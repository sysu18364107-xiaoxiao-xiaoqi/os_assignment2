  #include <stdio.h> 
  #include <stdlib.h>
  #include <string.h>
  #include <math.h>
  
  #define FRAME_SIZE 256 // 帧大小
  #define ADDRESSES_SIZE 1000 //address.txt虚拟地址条目数
  #define BinaryNum 100
  FILE *OutFile;//输出文件
  FILE *VirtualAddrFile;//虚拟地址文件
  FILE *AddrStoreFile;//存储地址文件
  
  int addresses[ADDRESSES_SIZE];//虚拟地址文件
  int FrameUse[FRAME_SIZE];//判断页帧是否被使用
  int binary[BinaryNum];//除2取余(地址)
  
  
  //转换二进制码
  int binary_to_int(int binary[],int ihead,int itail){
      int codeNum = 0;
      for (int i = ihead; i < itail; i++)
      { 
          codeNum +=  pow(2,i-ihead) * binary[i];
      }
      return codeNum;
  }
  
  int ReadFile()
  {
      OutFile = fopen("out.txt","w+");    
      if((VirtualAddrFile = fopen("addresses.txt","r"))== NULL) return 0;
      for(int i=0;(fscanf(VirtualAddrFile, "%d", &addresses[i]) != EOF);i++);
      fclose(VirtualAddrFile);
      return 0;
  }
  
  void initFrameUseArray()
  {
      for(int j = 0; j < FRAME_SIZE ; j++)
          FrameUse[j]  = -1;//-1没有进行存取的标志
  }
  
  void BinaryNumCount(int *binary,int temp){
      for(int count=0; temp!=0;count++)//temp对000000001按位和，那么只有第一位为1的时候，才会是1，正好是我们想要的结果。
          {
              binary[count] = temp & 1;//
              temp = (temp>>1);//向右移动一位
          }
  }//得到了反过来的二进制的数组
  
  int off_setCount(int * binary)
  {
      int off_set=0;
      for (int m = 0; m < 8; m++)
              off_set = off_set + pow(2,m) * binary[m];
      return off_set;
  }
  
  int main(void) {
      ReadFile();
      initFrameUseArray();
      
      //严格意义上说，这个就是页表
      char PhyMemory[FRAME_SIZE][FRAME_SIZE];//这个就是我们的物理内存的存放的值    
      int firstFram = 0;
      for(int i = 0; i <ADDRESSES_SIZE; i++){
          int binary[100]={0};
          BinaryNumCount(binary,addresses[i]);
          int page = binary_to_int(binary,8,16);//页号,从第8位开始算
          int off_set = off_setCount(binary);//偏移        
          
          int frame = 0;
          
          if(FrameUse[page] == -1){
              //发生了缺页错误。我们要去二进制文件进行读取。
              //以下是读取代码
              FILE *file;
              char *buffer;
              int x;
              file = fopen("BACKING_STORE.bin", "rb");
              fseek(file,FRAME_SIZE*page,0);
              buffer=(char *)malloc(FRAME_SIZE+1);
              fread(buffer,1,FRAME_SIZE,file);
              for ( x = 0; x < FRAME_SIZE; x++)
              {
                  PhyMemory[firstFram][x] = buffer[x];
              }
              free(buffer);
              fclose(file);
              FrameUse[page] = firstFram;
              frame = firstFram;
              firstFram++;
          }else{
              frame = FrameUse[page];
          }
          //得到了偏移量，帧表数值，结果是要让我们返回二者和起来的数字。  
          char value = PhyMemory[frame][off_set];//frame + offset 和起来的数值，以及对应的value
          int phyAddress[16];
          int y = 0;
          for(y = 0; y < 8; y++)
              phyAddress[y] = binary[y];
          for ( y = 8; y < 16; y++)
              phyAddress[y] = 0;
          
          int temp_f = frame;
          for(int phyCount = 8;temp_f != 0;phyCount++)
          {
              phyAddress[phyCount] = temp_f&1;
              temp_f= (temp_f>>1);
          }
          int physicalAddress = binary_to_int(phyAddress,0,16);
  
          printf("input %d   physcial %d   value:%d \n", addresses[i],physicalAddress,value);    
          char writes[BinaryNum] = "Virtual address: ";
          char VirtualAddressC[BinaryNum];
          char PhysicalAddressC[BinaryNum];
          char ValueS[BinaryNum];
          sprintf(VirtualAddressC,"%d",addresses[i]);
          sprintf(PhysicalAddressC,"%d",physicalAddress);
          sprintf(ValueS,"%d",value);
          strcat(writes,VirtualAddressC);
          strcat(writes," Physical address: ");
          strcat(writes,PhysicalAddressC);
          strcat(writes," Value: ");
          strcat(writes,ValueS);
          strcat(writes,"\n");
          fputs(writes,OutFile);
      }
      return 0;
  }
