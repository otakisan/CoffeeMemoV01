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
    NSString*   _databaseFilePath;      //  SQLiteのファイルパス。
}

static CoffeeMemoV01SQLite* _SQLite;

/**
 シングルトン取得みたいなもののように思われる
 */
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

/**
 iOSアプリ個別に用意されるSandBoxルート起点からのSQLite用ディレクトリパスの取得
 */
+ (NSString*)path
{
    static NSString* databaseFilePath = nil;       //  SQliteが利用するファイルのパス文字列。
    if (databaseFilePath) {
        return databaseFilePath;
    }
    
    //  Sandboxのドキュメントディレクトリを指定する。
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *directoryPath = [paths lastObject];
    
    //  Sandboxのドキュメントディレクトリ直下にあるCoffeeMemoV01.sqliteという名前のファイルへのファイルパスを作成。
    databaseFilePath = [directoryPath stringByAppendingPathComponent:@"CoffeeMemoV01.sqlite"];
    return databaseFilePath;
}

/**
 SQLiteファイルパスを保持しつつ初期化
 */
- (id)initWithPath:(NSString*)path
{
    self = [super init];
    if (self) {
        _databaseFilePath = path;
    }
    return self;
}

/**
 DBを作成する。
 既に存在する場合には何もしない。
 */
- (void)setup
{
    //  SQLiteがデータベース用に利用するファイルを決める。
    
    // データベースファイルが存在するかチェック
    if ([[NSFileManager defaultManager] fileExistsAtPath:_databaseFilePath]) {
        //  存在した場合、テーブル作成は終わっているので何もしない。
        return;
    }
    
    //  データベースファイルが存在していなかったなら、テーブルの準備をする

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
    
    // 自動でID列を作ってもらう場合は、pk integerを指定している
    // ユーザー定義列をキーにする場合には、primary keyというキーワードを指定している
    // コーヒーメモ的には、テイスティングの記録が5W1Hで記録できればいい。
    // カスタマイズについて、列を分けると列の数が増えすぎてしまうので、
    // 備考マスタからの文字列を備考に記録するか、カスタマイズ詳細テーブルを作成する。
    // 今回は複合キーはひとまずないけど、記述するとしたら
    // "create table watchers(pk integer, t_no integer, primary key(pk, t_no));"
    // というようになる。
    const char* sql =
    "create table tasting(id integer primary key autoincrement, tasting_time timestamp not null, store_id integer not null, bean_id integer not null, method_id integer not null, iced integer not null, size_id integer not null, food_id integer not null, aroma text not null, acidity text not null, body text not null, flavor text not null, description text not null, score integer not null, remarks text not null);"
    "create table store(id integer primary key autoincrement, name text not null, remarks text not null);"
    "create table method(id integer primary key autoincrement, name text not null, remarks text not null);"
    "create table size(id integer primary key autoincrement, name text not null, remarks text not null);"
    "create table food(id integer primary key autoincrement, name text not null, remarks text not null);"
    "create table bean(id integer primary key autoincrement, name text not null, three_letter text not null, icon blob not null, remarks text not null);"
    ;
    
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
    
    /*
     closeDBの前に下記が必要。
     というか、closeDBに組み入れたほうがよいのかもしれない。
     DBクローズの前に全てのステートメントを解放しないといけないらしい。
     http://ameblo.jp/xcc/entry-10248650639.html
     まさにこの本の作者のブログなんだけど…
     っと思ったら上のほうでやっていたみたい。
     
     sqlite3_stmt *pStmt;
     while( (pStmt = sqlite3_next_stmt(db, 0))!=0 ){
     sqlite3_finalize(pStmt);
     }

     */
    closeDB(database);
}

//  SQliteの利用開始。
static sqlite3* openDB(NSString* path)
{
    sqlite3* database = nil;
    
    // unix系のOSS由来で POSIXな関数を使っているものを使う時にはハマりポイントになるかも
    // [path UTF8String]ではなく、[path fileSystemRepresentation]を使用する必要があるらしい
    // NFCとNFDでことなるとか。HFS+の場合の都合みたいだけど、今はそういうものなんだってことで。
    // 文字列の長さが3bytes異なり、1codepoint分異なるとのこと。
    // 引数の数が異なる他のAPIもあるけど、下記の場合だと、ファイルがなければ作成されるオプションで動作する
    int result = sqlite3_open([path fileSystemRepresentation], &database);
    if (result != SQLITE_OK) {
        printf("SQliteの利用開始失敗 (%d) '%s'.\n", result, sqlite3_errmsg(database));
        return nil;
    }
    return database;
}

//  SQliteの利用終了。
static BOOL closeDB(sqlite3* database)
{
    int result = sqlite3_close(database);
    if (result != SQLITE_OK) {
        printf("SQliteの利用終了失敗 (%d) '%s'.\n", result, sqlite3_errmsg(database));
        return NO;
    }
    return YES;
}

//  SQliteのSQL文実行とエラー処理。
static BOOL stepStatement(sqlite3* database, sqlite3_stmt *statement)
{
	if (sqlite3_step(statement) == SQLITE_ERROR) {
		printf("Failed to sqlite3_step に失敗 '%s'.\n", sqlite3_errmsg(database));
        return NO;
	}
    return YES;
}

//  SQliteのSQL文実行用ステートメントの破棄とエラー処理。
static BOOL finalizeStatement(sqlite3* database, sqlite3_stmt *statement)
{
	if (sqlite3_finalize(statement) != SQLITE_OK) {
		printf("sqlite3_finalizeに失敗 '%s'.\n", sqlite3_errmsg(database));
        return NO;
    }
    return YES;
}


@end
