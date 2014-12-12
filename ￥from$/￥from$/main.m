//
//  main.m
//  ￥from$
//
//  Created by UMBLR on 2014/12/11.
//  Copyright (c) 2014年 raus0. All rights reserved.
//

#import <Foundation/Foundation.h>
#define rate 102
int main(int argc, const char * argv[])
{

    double yen;
    double doll;
    doll = 10.5;
    
    yen = doll * rate;
    NSLog(@"%.1fドルは%.1f円です",doll,yen);
    
    return 0;
}