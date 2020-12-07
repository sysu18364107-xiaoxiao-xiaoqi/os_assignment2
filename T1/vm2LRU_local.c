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

void insertTLB(TLBlist* TLB, int pageNum, int frameNum) {

        if (TLB->num <= TLB_Size) {//TLB未满
                //node初始化
                node* temp = (node*)malloc(sizeof(node));
                node* preNode;
                temp->pageNum = pageNum;
                temp->frameNum = frameNum;
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
                insertTLB(TLB, pageNum, frameNum);
        }
}

void ChangePage(int pageNum, int FinalFrameNum, char memory[][FRAME_SIZE], int page[][2]) {
        FILE* diskFile;
        diskFile = fopen("BACKING_STORE.bin", "rb");
        fseek(diskFile, FRAME_SIZE * pageNum, 0);
        char* frame = (char*)malloc(257);
        fread(frame, 1, FRAME_SIZE, diskFile);
        for (int i = 0; i < FRAME_SIZE; i++) {
                memory[FinalFrameNum][i] = frame[i];
        }
        //更新page
        page[pageNum][1] = 1;
        page[pageNum][0] = FinalFrameNum;
}

void LRUinTLB(TLBlist* TLB,node* accessedNode) {
        if (TLB->num <= TLB_Size) {//TLB未满
                if (accessedNode->next != NULL && accessedNode->pre != NULL) {//node不是rear也不是front
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
                if(accessedNode->pre == NULL && accessedNode->next != NULL) {//node为front，但不是rear
                        //删除node
                        accessedNode->next->pre = NULL;
                        TLB->front = accessedNode->next;
                        //加入node
                        TLB->rear->next = accessedNode;
                        accessedNode->next = NULL;
                        accessedNode->pre = TLB->rear;
                        TLB->rear = accessedNode;
                }
                //node为rear 不用操作
        }
}
void BinaryNumCount(int *binary,int temp){
    for(int count=0; temp!=0;count++)//temp对000000001按位和，那么只有第一位为1的时候，才会是1，正好是我们想要的结果。
        {
            binary[count] = temp & 1;//
            temp = (temp>>1);//向右移动一位
        }
}//得到了反过来的二进制的数组


int TLBHit = 0;
int page_default = 0;
int firstFram = 0;
int point = 0;
int point_TLB = 0;
int FinalFrameNum = 0;//指向内存最后插入的frame number后的空frame
int main(void) {
    ReadFile();
    int  pageC[FRAME_SIZE][2]={0};
    //创建TLB
    TLBlist *TLBC = (TLBlist*)malloc(sizeof(TLBlist));
    initTLB(TLBC);

    int page_default = 0;
    //严格意义上说，这个就是页表
    //设定这个-1为我们未存取的情况
    int point_frame = 0;
    int point_TLB = 0;
    for(int i = 0; i <ADDRESSES_SIZE; i++){
        int binary[100]={0};
        BinaryNumCount(binary,addresses[i]);
        int page = binary_to_int(binary,8,16);//页号
        int pageNum=page;
        int frame = -1;

        int frameNum;
        int inTLB = 0;
        node* tempC = TLBC->front;
        if (TLBC->num) {//TLB不为空
                while (tempC != NULL) {
                        if (tempC->pageNum == pageNum) {
                                //printf("  TLB  ");
                                frameNum = tempC->frameNum;
                                TLBHit++;
                                printf("TLB命中成功！ TLBHit : %d     ",TLBHit);
                                LRUinTLB(TLBC,tempC);
                                inTLB = 1;
                                break;
                        }
                        tempC = tempC->next;
                }
        }

        if (inTLB == 0) {//不在TLB中
                if (pageC[pageNum][1]) {//在内存并且不在TLB中
                        printf("TLB命中失败      ");
                        printf("  page 在内存中  ");
                        frameNum = pageC[pageNum][0];
                        //加入TLB
                        insertTLB(TLBC, pageNum, frameNum);
                }
                else {//缺页错误
                        printf("TLB命中失败      ");
                        page_default++;
                        printf("出现了一次缺页！ page_default : %d", page_default);
                        ChangePage(pageNum, FinalFrameNum, PhyMemory, pageC);
                        insertTLB(TLBC, pageNum, frameNum);
                        frameNum = FinalFrameNum;
                        FinalFrameNum++;
                }
        }
        int phyAddress[16];
        int y = 0;
        for(y = 0; y < 8; y++){
            phyAddress[y] = binary[y];
        }
        for ( y = 8; y < 16; y++)
        {
            phyAddress[y] = 0;
        }
        int phyCount = 8;
        int temp_f = frameNum;
        while (temp_f != 0)
        {
            phyAddress[phyCount] = temp_f&1;
            temp_f= (temp_f>>1);
            phyCount++;
        }
        int physicalAddress = binary_to_int(phyAddress,0,16);

        printf("TLBHit %d   page_default %d   \n", TLBHit,page_default);    
    }
    
    double TLB_p = (double)TLBHit/1000;
    double page = (double)page_default/1000;
    printf("TLBHIT :  %lf   ,pageFalut: %lf \n" ,TLB_p ,page);
    return 0;
}
