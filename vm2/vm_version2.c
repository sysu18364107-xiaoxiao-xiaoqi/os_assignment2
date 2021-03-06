#include <stdio.h> 
#include <stdlib.h>
#include <string.h>
#include <math.h>

#define FRAME_SIZE 256 // 帧大小
#define ADDRESSES_SIZE 1000 //address.txt虚拟地址条目数
#define BinaryNum 100
#define TLB_Size 16 //TLB大小

FILE *OutFile;//输出文件
FILE *VirtualAddrFile;//虚拟地址文件
FILE *AddrStoreFile;//存储地址文件

int addresses[ADDRESSES_SIZE];//虚拟地址文件
int FrameUse[FRAME_SIZE/2];//判断页帧是否被使用
int binary[BinaryNum];//除2取余(地址)
char PhyMemory[FRAME_SIZE][FRAME_SIZE];

//转换二进制码
int binary_to_int(int binary[],int ihead,int itail){
    int codeNum = 0;
    for (int i = ihead; i < itail; i++)
        codeNum +=  pow(2,i-ihead) * binary[i];
    return codeNum;
}

//读取文件
int ReadFile()
{
    int i=0;
    if((VirtualAddrFile = fopen("addresses.txt","r"))== NULL) return 0;
    while(fscanf(VirtualAddrFile, "%d", &addresses[i]) != EOF) i++;
    fclose(VirtualAddrFile);//关闭文件
}


typedef struct Node node;
typedef struct Node {
        int pageNum;
        int frameNum;
        int inMemory;
        node* next;
        node* pre;
}Node;

typedef struct {
        node* front;
        node* rear;
        int num;
}TLBlist;

void initTLB(TLBlist* TLB) {
        TLB->front = NULL;
        TLB->rear = NULL;
        TLB->num = 0;
}

void delFullTLB(TLBlist* TLB) {//仅队列满时调用
        node* temp = TLB->front;
        //删除node
        TLB->front = TLB->front->next;
        free(temp);
        TLB->front->pre = NULL;
        TLB->num--;
}

void insertTLB(TLBlist* TLB, int page, int frame) {

        if (TLB->num <= TLB_Size) {//TLB未满
                //node初始化
                node* temp = (node*)malloc(sizeof(node));
                node* preNode;
                temp->pageNum = page;
                temp->frameNum = frame;
                temp->inMemory = 1;
                temp->next = NULL;
                temp->pre = NULL;
                //加入TLB
                if (TLB->rear == NULL) {//第一个加入node
                        TLB->front = temp;
                        TLB->rear = temp;
                        TLB->num++;
                }

                else {
                        preNode = TLB->rear;
                        TLB->rear->next = temp;
                        TLB->rear = temp;
                        TLB->rear->pre = preNode;
                        TLB->num++;
                }
        }
        else {//TLB满，FIFO策略
                //清除最后的node
                delFullTLB(TLB);
                //加入node
                insertTLB(TLB, page, frame);
        }
}

void ChangePage(int page, int rearFrameNum, char PhyMemory[][FRAME_SIZE], int pageCArecord[],int pageCAframe[]) {
        AddrStoreFile = fopen("BACKING_STORE.bin", "rb");
        fseek(AddrStoreFile, FRAME_SIZE * page, 0);
        char* buffer = (char*)malloc(257);
        fread(buffer, 1, FRAME_SIZE, AddrStoreFile);
        for (int i = 0; i < FRAME_SIZE; i++) {
                PhyMemory[rearFrameNum][i] = buffer[i];
        }
        //更新page
        pageCArecord[page] = 1;//更新页面占有和最新的frame
        pageCAframe[page] = rearFrameNum;
}

void LRUinTLB(TLBlist* TLB,node* accessedNode) {
        if (TLB->num <= TLB_Size) {//TLB未满
                if (accessedNode->next != NULL && accessedNode->pre != NULL) {//非前后节点
                        //删除node
                        node* temp = accessedNode;
                        accessedNode->pre->next = accessedNode->next;
                        accessedNode->next->pre = accessedNode->pre;
                        //加入node
                        TLB->rear->next = accessedNode;
                        accessedNode->next = NULL;
                        accessedNode->pre = TLB->rear;
                        TLB->rear = accessedNode;
                }
                if(accessedNode->pre == NULL && accessedNode->next != NULL) {//为前结点
                        //删除node
                        accessedNode->next->pre = NULL;
                        TLB->front = accessedNode->next;
                        //加入node
                        TLB->rear->next = accessedNode;
                        accessedNode->next = NULL;
                        accessedNode->pre = TLB->rear;
                        TLB->rear = accessedNode;
                }
        }
}



int TLBHit = 0;
int page_default = 0;
int firstFram = 0;
int rearFrameNum = 0;//指向内存最后插入的frame number后的空frame
int main(void) {
    ReadFile();
    int pageCArecord[FRAME_SIZE]={0};
    int pageCAframe[FRAME_SIZE]={0};

    //创建TLB
    TLBlist *TLBC = (TLBlist*)malloc(sizeof(TLBlist));
    initTLB(TLBC);


    for(int i = 0; i <ADDRESSES_SIZE; i++){
        int page = (addresses[i]>>8)&255;
        int offset = (addresses[i]&255);
        int frame;
        //遍历TLB，看是否在其中
        int inTLB = 0;
        node* tempC = TLBC->front;
        if (TLBC->num) {//TLB不为空
                while (tempC != NULL) {
                        if (tempC->pageNum == page) {
                                //printf("  TLB  ");
                                frame = tempC->frameNum;
                                TLBHit++;
                                printf("出现一次TLB命中   ");
                                printf("TLBHit is %d      ",TLBHit);
                                inTLB = 1;
                                break;
                        }
                        tempC = tempC->next;
                }
        }

        if (inTLB == 0) {//不在TLB中
                if (pageCArecord[page]) {//在内存并且不在TLB中
                        printf("TLB命中失败      ");
                        printf("page 在内存中     ");
                        printf("TLBHit is %d      ",TLBHit);
                        printf("page_default is %d      ",page_default);
                        frame = pageCAframe[page];
                        //加入TLB
                        insertTLB(TLBC, page, frame);
                }
                else {//缺页错误
                        printf("TLB命中失败      ");
                        printf("出现了一次缺页！   ");
                        page_default++;
                        printf("TLBHit is %d      ",TLBHit);
                        printf("page_default is %d      ",page_default);
                        ChangePage(page, rearFrameNum, PhyMemory, pageCArecord,pageCAframe);
                        insertTLB(TLBC, page, frame);//注意page和TLB要同时更新
                        frame = rearFrameNum;
                        rearFrameNum++;
                }
        
        }
        printf("value is %d", PhyMemory[frame][offset]);//打印出存储的值
        if (i != ADDRESSES_SIZE - 1)
            printf("\n");


        
    }
    
    double TLB_p = (double)TLBHit/1000;
    double page_p = (double)page_default/1000;
    printf("\nTLBHIT :  %lf   ,pageFalut: %lf \n" ,TLB_p ,page_p);
    return 0;
}
