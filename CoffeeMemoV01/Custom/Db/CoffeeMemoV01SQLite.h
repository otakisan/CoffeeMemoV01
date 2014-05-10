//
//  CoffeeMemoV01SQLite.h
//  CoffeeMemoV01
//
//  Created by Takashi Ikeda on 2014/05/09.
//  Copyright (c) 2014年 TI. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CoffeeMemoV01SQLite : NSObject

/**
 共有インスタンス
 */
+(CoffeeMemoV01SQLite*)sharedSQLite;

// DBフルパス
+(NSString*)path;

// arrayに入っている古い成績
//-(void)convert:(NSArray*)array;

-(NSArray*)fetchRecords;

-(id)addRecord:(int)score level:(int)level member:(id)member;

-(NSArray*)fetchMembers;

@end
