#include<stdio.h>
#include<stdatomic.h>
#include<pthread.h>

_Atomic long acnt;
int cnt;
void *adding(void *input) {
    for(long i=0; i<10000000000000; i++) {
        acnt++;
        cnt++;
    }
    pthread_exit(NULL);
}

int main() {
    pthread_t tid[10];
    for(int i=0; i<10; i++)
        pthread_create(&tid[i],NULL,adding,NULL);
    for(int i=0; i<10; i++)
        pthread_join(tid[i],NULL);

    printf("the value of acnt is %d\n", acnt);
    printf("the value of cnt is %d\n", cnt);
    return 0;
}
