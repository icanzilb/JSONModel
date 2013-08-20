//
//  KeyMappingTests.m
//  JSONModelDemo
//
//  Created by Marin Todorov on 19/12/2012.
//  Copyright (c) 2012 Underplot ltd. All rights reserved.
//

#import "KeyMappingTests.h"
#import "JSONModelLib.h"
#import "GitHubKeyMapRepoModel.h"
#import "GitHubKeyMapRepoModelDict.h"
#import "GitHubRepoModelForUSMapper.h"


#pragma mark - TestModel class
@interface TestModel: JSONModel

@property (strong, nonatomic) NSString* text1;
@property (strong, nonatomic) NSString<Optional>* text2;

@end
@implementation TestModel

+(JSONKeyMapper*)keyMapper
{
    return [[JSONKeyMapper alloc] initWithDictionary:@{
            @"texts.text1": @"text1",
            @"texts.text2.value": @"text2"
            }];
}

@end

#pragma mark - global key mapper test model
@interface GlobalModel: JSONModel
@property (strong, nonatomic) NSString* name;
@end
@implementation GlobalModel
@end

#pragma mark - KeyMappingTests unit test

@implementation KeyMappingTests
{
    NSArray* json;
}

-(void)setUp
{
    [super setUp];
    
    NSString* filePath = [[NSBundle bundleForClass:[JSONModel class]].resourcePath stringByAppendingPathComponent:@"github-iphone.json"];
    NSData* jsonData = [NSData dataWithContentsOfFile:filePath];
    
    STAssertNotNil(jsonData, @"Can't fetch test data file contents.");
    
    NSError* err;
    NSDictionary* jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&err];
    json = jsonDict[@"repositories"];
    
    STAssertNil(err, [err localizedDescription]);
    STAssertNotNil(jsonData, @"Could not load the test data file.");
}

-(void)testKeyMapping
{
    NSDictionary* repo1 = json[0];
    GitHubKeyMapRepoModel* model1 = [[GitHubKeyMapRepoModel alloc] initWithDictionary:repo1 error:nil];
    STAssertNotNil(model1, @"Could not initialize model");
    STAssertNotNil(model1.__description, @"__description is nil");
    STAssertTrue([model1.__description isEqualToString:repo1[@"description"]], @"__description was not mapped properly");
    
    NSDictionary* dict = [model1 toDictionary];
    STAssertNotNil(dict[@"description"], @"description not exported properly");
}

-(void)testKeyMappingWithDict
{
    NSDictionary* repo1 = json[0];
    GitHubKeyMapRepoModelDict* model1 = [[GitHubKeyMapRepoModelDict alloc] initWithDictionary:repo1 error:nil];
    STAssertNotNil(model1, @"Could not initialize model");
    STAssertNotNil(model1.__description, @"__description is nil");
    STAssertTrue([model1.__description isEqualToString:repo1[@"description"]], @"__description was not mapped properly");

    NSDictionary* dict = [model1 toDictionary];
    STAssertNotNil(dict[@"description"], @"description not exported properly");
}

-(void)testUnderscoreMapper
{
    NSString* jsonString = @"{\"pushed_at\":\"2012-12-18T19:21:35-08:00\",\"created_at\":\"2012-12-18T19:21:35-08:00\",\"a_very_long_property_name\":10000}";
    GitHubRepoModelForUSMapper* m = [[GitHubRepoModelForUSMapper alloc] initWithString:jsonString error:nil];
    STAssertNotNil(m, @"Could not initialize model from string");
    
    STAssertTrue([m.pushedAt compare:[NSDate dateWithTimeIntervalSinceReferenceDate:0] ]==NSOrderedDescending, @"pushedAt is not initialized");
    STAssertTrue([m.createdAt compare:[NSDate dateWithTimeIntervalSinceReferenceDate:0] ]==NSOrderedDescending, @"createdAt is not initialized");
    STAssertTrue(m.aVeryLongPropertyName == 10000, @"aVeryLongPropertyName is not 10000");
    
    //export
    NSDictionary* dict = [m toDictionary];
    STAssertNotNil(dict, @"toDictionary failed");
    
    STAssertNotNil(dict[@"pushed_at"], @"pushed_at not exported");
    STAssertNotNil(dict[@"created_at"], @"pushed_at not exported");
    STAssertTrue([dict[@"a_very_long_property_name"] intValue]==10000,@"a_very_long_property_name not exported properly");
    
}

-(void)testKeyMapperCaching
{
    //simulate fetching different models, so the keyMapper cache is used
    
    [self testUnderscoreMapper];
    [self testKeyMapping];
    [self testUnderscoreMapper];
    [self testKeyMapping];
    [self testUnderscoreMapper];
    [self testKeyMapping];
}

-(void)testKeyPathKeyMapping
{
    //input dictioanry for TestModel
    NSDictionary* dict = @{
        @"texts": @{
            @"text1": @"TEST!!!",
            @"text2": @{@"value":@"MEST"}
        }
    };
    
    NSError* err = nil;
    TestModel* model = [[TestModel alloc] initWithDictionary:dict error:&err];
    
    STAssertTrue(err==nil, @"Error creating TestModel: %@", [err localizedDescription]);
    STAssertTrue(model!=nil, @"TestModel instance is nil");
    
    STAssertTrue([model.text1 isEqualToString:@"TEST!!!"], @"text1 is not 'TEST!!!'");
    STAssertTrue([model.text2 isEqualToString:@"MEST"], @"text1 is not 'MEST'");
    
    NSDictionary* toDict = [model toDictionary];
    
    STAssertTrue([toDict[@"texts"][@"text1"] isEqualToString:@"TEST!!!"], @"toDict.texts.text1 is not 'TEST!!!'");
    STAssertTrue([toDict[@"texts"][@"text2"][@"value"] isEqualToString:@"MEST"], @"toDict.texts.text2.value is not 'MEST'");
}

-(void)testGlobalKeyMapper
{
    NSString* jsonString1 = @"{\"name\": \"NAME IN CAPITALS\"}";
    GlobalModel* global1 = [[GlobalModel alloc] initWithString:jsonString1
                                                         error:nil];
    STAssertNotNil(global1, @"model did not initialize with proper json");
    
    [JSONModel setGlobalKeyMapper:[[JSONKeyMapper alloc] initWithDictionary:@{
        @"name1":@"name"
     }]];
    
    NSString* jsonString2 = @"{\"name1\": \"NAME IN CAPITALS\"}";
    GlobalModel* global2 = [[GlobalModel alloc] initWithString:jsonString2
                                                         error:nil];
    STAssertNotNil(global2, @"model did not initialize with proper json");
    
    [JSONModel setGlobalKeyMapper:nil];

    GlobalModel* global3 = [[GlobalModel alloc] initWithString:jsonString2
                                                         error:nil];
    STAssertNil(global3, @"model supposed to be nil");
}

@end