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


//对LRU数据结构的实现
#define Nothingness -1

struct node{
    int key;
    int value;
    struct node* prev;
    struct node* next;
};//双向链表

struct hash{
    struct node* unused;//数据的未使用时长
    struct hash* next;//拉链法解决哈希冲突
};//哈希表结构

typedef struct {    
    int size;//当前缓存大小
    int capacity;//缓存容量
    struct hash* table;//哈希表
    //维护一个双向链表用于记录 数据的未使用时长
    struct node* head;//后继 指向 最近使用的数据
    struct node* tail;//前驱 指向 最久未使用的数据    
} LRUCache;

struct hash* HashMap(struct hash* table, int key, int capacity)
{//哈希地址
    int addr = key % capacity;//求余数
    return &table[addr];
}

void HeadInsertion(struct node* head, struct node* cur)
{//双链表头插法
    if (cur->prev == NULL && cur->next == NULL)
    {// cur 不在链表中        
        cur->prev = head;
        cur->next = head->next;
        head->next->prev = cur;
        head->next = cur;
    }
    else
    {// cur 在链表中
        struct node* fisrt = head->next;//链表的第一个数据结点
        if ( fisrt != cur)
        {//cur 是否已在第一个
            cur->prev->next = cur->next;//改变前驱结点指向
            cur->next->prev = cur->prev;//改变后继结点指向
            cur->next = fisrt;//插入到第一个结点位置
            cur->prev = head;
            head->next = cur;
            fisrt->prev = cur;
        }
    }
}

LRUCache* lRUCacheCreate(int capacity) {
    /*if (capacity <= 0)
    {//传参检查
        return NULL;
    }*/
    LRUCache* obj = (LRUCache*)malloc(sizeof(LRUCache));
    obj->table = (struct hash*)malloc(capacity * sizeof(struct hash));
    memset(obj->table, 0, capacity * sizeof(struct hash));
    obj->head = (struct node*)malloc(sizeof(struct node));
    obj->tail = (struct node*)malloc(sizeof(struct node));
    //创建头、尾结点并初始化
    obj->head->prev = NULL;
    obj->head->next = obj->tail;
    obj->tail->prev = obj->head;
    obj->tail->next = NULL;
    //初始化缓存 大小 和 容量 
    obj->size = 0;
    obj->capacity = capacity;
    return obj;
}

int lRUCacheGet(LRUCache* obj, int key) {
    struct hash* addr = HashMap(obj->table, key, obj->capacity);//取得哈希地址
    addr = addr->next;//跳过头结点
    if (addr == NULL){
        return Nothingness;
    }
    while ( addr->next != NULL && addr->unused->key != key)
    {//寻找密钥是否存在
        addr = addr->next;
    }
    if (addr->unused->key == key)
    {//查找成功
        HeadInsertion(obj->head, addr->unused);//更新至表头
        return addr->unused->value;
    }
    return Nothingness;
}

void lRUCachePut(LRUCache* obj, int key, int value) {
    struct hash* addr = HashMap(obj->table, key, obj->capacity);//取得哈希地址
    if (lRUCacheGet(obj, key) == Nothingness)
    {//密钥不存在
        if (obj->size >= obj->capacity)
        {//缓存容量达到上限
            struct node* last = obj->tail->prev;//最后一个数据结点
            struct hash* remove = HashMap(obj->table, last->key, obj->capacity);//舍弃结点的哈希地址
            struct hash* ptr = remove;
            remove = remove->next;//跳过头结点
            while (remove->unused->key != last->key)
            {//找到最久未使用的结点
                ptr = remove;
                remove = remove->next;
            }
            ptr->next = remove->next;//在 table[last->key % capacity] 链表中删除结点
            remove->next = NULL;
            remove->unused = NULL;//解除映射
            free(remove);//回收资源
            struct hash* new_node = (struct hash*)malloc(sizeof(struct hash));
            new_node->next = addr->next;//连接到 table[key % capacity] 的链表中
            addr->next = new_node;
            new_node->unused = last;//最大化利用双链表中的结点，对其重映射(节约空间)
            last->key = key;//重新赋值
            last->value = value;
            HeadInsertion(obj->head, last);//更新最近使用的数据
        }
        else
        {//缓存未达上限
            //创建(密钥\数据)结点,并建立映射
            struct hash* new_node = (struct hash*)malloc(sizeof(struct hash));
            new_node->unused = (struct node*)malloc(sizeof(struct node));
            new_node->next = addr->next;//连接到 table[key % capacity] 的链表中
            addr->next = new_node;
            new_node->unused->prev = NULL;//标记该结点是新创建的,不在双向链表中
            new_node->unused->next = NULL;
            new_node->unused->key = key;//插入密钥
            new_node->unused->value = value;//插入数据
            HeadInsertion(obj->head,new_node->unused);//更新最近使用的数据
            ++(obj->size);//缓存大小+1
        }
    }
    else
    {//密钥已存在
    // lRUCacheGet 函数已经更新双链表表头，故此处不用更新
        obj->head->next->value = value;//替换数据值
    }
}

void lRUCacheFree(LRUCache* obj) {
    free(obj->table);
    free(obj->head);
    free(obj->tail);
    free(obj);
}


int lRUCacheGetoldest(LRUCache* obj){
    //如果说没有满的话，那我们就返回-1就好了
    if(obj->size >= obj->capacity){
        //满了
        return obj->tail->prev->value;
    }else{
        //没有满，不需要移除最后的entry
        return -1 ;
    }
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

void demandPaging(int pageNum, int rearFrameNum, char memory[][256], int page[][2]) {
        FILE* diskFile;
        diskFile = fopen("BACKING_STORE.bin", "rb");
        fseek(diskFile, 256 * pageNum, 0);
        char* frame = (char*)malloc(257);
        fread(frame, 1, 256, diskFile);
        for (int i = 0; i < 256; i++) {
                memory[rearFrameNum][i] = frame[i];
        }
        //更新page
        page[pageNum][1] = 1;
        page[pageNum][0] = rearFrameNum;
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



struct node TLB[FRAME_SIZE];
int TLBHit = 0;
int page_default = 0;
int firstFram = 0;
int point = 0;
int point_TLB = 0;
int rearFrameNum = 0;//指向内存最后插入的frame number后的空frame
int main(void) {
    ReadFile();
    int  pageC[256][2];
    for(int i=0;i<256;i++)pageC[i][1]=0;
    //创建TLB
    TLBlist *TLBC = (TLBlist*)malloc(sizeof(TLBlist));
    initTLB(TLBC);

    //理论上说，为了代码的可阅读性，应该多放几个函数,但是c语言的函数传递，指针调用有点复杂，在这里就不调用了，其实俺觉得这题用别的编程语言也可以
    //以下是对每一个数据的处理。
    //处理的主要核心思路是，得到每一个int数字的二进制字符串，并且，从右往左数，0-7原封不动的给我们的物理地址
    //随后先来先得，将帧玛从0-255依次分配，并且记录下来，这里我觉得可以采用int数组的形式来存取，不需要使用map
    
    LRUCache *page_map;
    LRUCache *page_TLB;
    page_TLB = lRUCacheCreate(16);
    page_map = lRUCacheCreate(128);



    int TLBHitTimes = 0;
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
                                TLBHitTimes++;
                                printf("TLB命中成功！ TLBHitTimes : %d     ",TLBHitTimes);
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
                        demandPaging(pageNum, rearFrameNum, PhyMemory, pageC);
                        frameNum = rearFrameNum;
                        rearFrameNum++;
                }
        }


        //实现map很麻烦，这里我们就反过来使用我们之前的map[]数组，key用来存放帧表，value放页表，搜查我们使用便利
        //在实际中，应该是使用map，rb_tree来实现这一对应的功能，但是老师说语言不是问题，我觉得完成任务，这二者是没有差别的
        

        //现在我们得到了我们想要的数据，一个是偏移量，一个是对应的帧表数值，结果是要让我们返回二者和起来的数字。
        //frame + offset 和起来的数值，以及对应的value
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

        printf("TLBHitTimes %d   page_default %d   \n", TLBHitTimes,page_default);    
    }
    
    double TLB_p = (double)TLBHitTimes/1000;
    double page = (double)page_default/1000;
    printf("TLBHIT :  %lf   ,pageFalut: %lf \n" ,TLB_p ,page);
    lRUCacheFree(page_TLB);
    lRUCacheFree(page_map);
    return 0;
}
