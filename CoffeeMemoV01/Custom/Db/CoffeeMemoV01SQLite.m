//
//  CoffeeMemoV01SQLite.m
//  CoffeeMemoV01
//
//  Created by Takashi Ikeda on 2014/05/09.
//  Copyright (c) 2014年 TI. All rights reserved.
//
#import <sqlite3.h>

#import "CoffeeMemoV01SQLite.h"

@implementation CoffeeMemoV01SQLite{
}

static CoffeeMemoV01SQLite* _SQLite;

+ (CoffeeMemoV01SQLite*)sharedSQLite
{
    // 1回だけ処理を実行させるための変数
    static dispatch_once_t onceToken;
    
    // dispatch_once()は最初の１度だけは処理するが、それ以降は何度呼ばれても何もしない
    // アプリケーション起動後、１度だけ実行される
    dispatch_once(&onceToken, ^{
        _SQLite = [[CoffeeMemoV01SQLite alloc] initWithPath:self.path];
        [_SQLite setup];
    });
    
    return _SQLite;
}

- (id)initWithPath:(NSString*)path
{
    self = [super init];
    if (self) {
        _databaseFilePath = path;
    }
    return self;
}

- (void)setup
{
    //  SQLiteがデータベース用に利用するファイルを決める。
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:_databaseFilePath]) {        // データベースファイルが存在するかチェック。
        //  存在した場合、テーブル作成は終わっているので何もしない。
        return;
    }
    
    //  データベースファイルが存在していなかったなら、テーブルの準備をする。
    
    /*
     //  次のようにアプリケーションバンドルに置いたSQLiteファイルを初期データとして使う事も可能。その場合、アプリケーションバンドルは書き込み不可なので
     //  ドキュメントディレクトリへコピーしておく。
     NSString* resourcePath = [[NSBundle mainBundle] pathForResource:@"MBGameRecords" ofType:@"sqlite"];   //  アプリケーションバンドルに置いたSQLiteファイル
     NSError* error = nil;
     if ([[NSFileManager defaultManager] copyItemAtPath:resourcePath toPath:databaseFilePath error:&error] == NO) {
     //  コピー先に同名ファイルがあった場合もNOが戻るが、今回はファイルがない事は確認済み。したがってあきらかなエラー。
     NSLog(@"error = %@", [error localizedDescription]);
     }
     return;
     */
    
    //  このサンプルでは、やっていませんが…
    //  　ここからデータベースファイルを作成初期化しますが、一番最初にファイルの存在で初期化済みかどうかを判断しているので、厳密におこなうなら
    //  MBGameRecords.sqliteではなく一時的な名前、またはテンポラリディレクトリでファイルを初期化するべきです。
    //  　そして、完全に初期化が成功したときだけ名前をMBGameRecords.sqliteにするまたはテンポラリディレクトリから持ってくるようにする。
    //  そのようにした方がより適切です。
    
    sqlite3* database = openDB(_databaseFilePath);
    if (database == nil) {  //  データベースのオープンに失敗した。
        return;
    }
    const char* sql = "create table records(pk integer primary key autoincrement, s_no integer, score integer, level integer, date timestamp);"
    "create table students(s_no integer primary key, name text, sex integer, class integer);"
    "create table watchers(pk integer, t_no integer, primary key(pk, t_no));"
    "create table teachers(t_no integer primary key, name text)";
    const char* next_sql = sql;
    do {
        sqlite3_stmt* statement = nil;
        int result = sqlite3_prepare_v2(database, next_sql, -1, &statement, &next_sql); //	ステートメント準備。
        if (result != SQLITE_OK) {
            printf("テーブル作成に失敗 (%d) '%s'.\n", result, sqlite3_errmsg(database));
            finalizeStatement(database, statement);
            closeDB(database);
            return;
        }
        if (stepStatement(database, statement) == NO) {  //  失敗した。
            printf("テーブル作成に失敗\n");
            finalizeStatement(database, statement);
            closeDB(database);
            return;
        }
        if (finalizeStatement(database, statement) == NO) {  //  失敗した。
            printf("テーブル作成に失敗\n");
            closeDB(database);
            return;
        }
    } while (*next_sql != 0);   //  C文字列終端コードではないならループ
    
    //  生徒／教師名簿取り出し。
    NSString* path = [[NSBundle mainBundle] pathForResource:@"MBGameMembers" ofType:@"plist"];
    NSDictionary* dic = [NSDictionary dictionaryWithContentsOfFile:path];
    
    //  SQLite側生徒名簿作成
    NSArray* students = dic[@"students"];               //  -objectForKey:の短縮構文。
    if (addStudent(database, 0, nil, 0, 0) == NO) {     //  無名用
        printf("無名生徒の登録に失敗\n");
        closeDB(database);
        return; //  失敗した。
    }
    for (NSDictionary* student in students) {
        if (addStudent(database, [student[@"number"] intValue], student[@"name"], [student[@"sex"] intValue], [student[@"class"] intValue]) == NO) {
            printf("生徒登録に失敗\n");
            closeDB(database);
            return; //  失敗した。
        }
    }
    NSArray* teachers = dic[@"teachers"];
    for (NSDictionary* teacher in teachers) {
        if (addTeacher(database, [teacher[@"number"] intValue], teacher[@"name"]) == NO) {
            printf("教師登録に失敗\n");
            closeDB(database);
            return; //  失敗した。
        }
    }
    closeDB(database);
}


@end
