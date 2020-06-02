#include<stdio.h>
#include<stdatomic.h>
#include<pthread.h>

_Atomic long acnt, c0, c1, c2, c3, c4, c5, c6, c7, c8;
int cnt;
void *adding(void *input)
{
    for(int i=0; i<10000000; i++)
    {
        acnt++;
//        cnt++;
    }
    pthread_exit(NULL);
}
int main()
{
    c0 = 1;
    c1 = 1;
    c2 = 1;
    c3 = 1;
    c4 = 1;
    c5 = 1;
    c6 = 1;
    c7 = 1;
    c8 = 1;
    pthread_t tid[10];
    for(int i=0; i<10; i++)
        pthread_create(&tid[i],NULL,adding,NULL);
    for(int i=0; i<10; i++)
        pthread_join(tid[i],NULL);

    printf("the value of acnt is %lu\n", acnt);
    printf("the value of cnt is %d\n", cnt);
    return 0;
}

