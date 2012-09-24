#import "Kiwi.h"

#pragma mark - Setup once: classes
@interface Transaction : NSObject

@property(nonatomic,strong) NSString *payee;
@property(nonatomic,strong) NSNumber *amount;
@property(nonatomic,strong) NSDate   *date;

@end

@implementation Transaction

@synthesize payee, amount, date;

@end


SPEC_BEGIN(CollectionOperatorTests)

NSMutableArray *transactions = [[NSMutableArray alloc] initWithCapacity:10];
NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];

#pragma mark - Setup once: data, helpers
beforeAll(^{
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    
    NSArray *data = @[
    @[@"Green Power", @120.00, @"Dec 1, 2009"],
    @[@"Green Power", @150.00, @"Jan 1, 2010"],
    @[@"Green Power", @170.00, @"Feb 15, 2010"],
    @[@"Car Loan", @250.00, @"Jan 15, 2010"],
    @[@"Car Loan", @250.00, @"Feb 15, 2010"],
    @[@"Car Loan", @250.00, @"Mar 15, 2010"],
    @[@"General Cable", @120.00, @"Dec 1, 2009"],
    @[@"General Cable", @155.00, @"Jan 1, 2010"]
    ];
    
    [transactions addObject:[[Transaction alloc] init]]; // can handle nil value
    
    for (NSArray *row in data) {
        Transaction *item = [[Transaction alloc] init];
        item.payee  = [row objectAtIndex:0];
        item.amount = [row objectAtIndex:1];
        item.date   = [dateFormatter dateFromString:[row objectAtIndex:2]];
        [transactions addObject:item];
    }
});


#pragma mark - Examples

#pragma mark Simple collection operators
describe(@"Simple Collection Operators", ^{

    it(@"calculates average", ^{
        double expected = 162.78;
        
        double sum = 0;
        for (Transaction *transaction in transactions) {
            sum += [transaction.amount intValue];
        }
        NSNumber *avg1 = [NSNumber numberWithDouble:(sum / [transactions count])];
        [[avg1 should] equal:expected withDelta:0.01];

        NSNumber *avg2 = [transactions valueForKeyPath:@"@avg.amount"];
        [[avg2 should] equal:expected withDelta:0.01];
    });
    
    it(@"counts collection", ^{
        NSNumber *expected = [NSNumber numberWithInt:9];
        
        NSNumber *count1 = [NSNumber numberWithInt:[transactions count]];
        [[count1 should] equal:expected];
        
        NSNumber *count2 = [transactions valueForKeyPath:@"@count"];
        [[count2 should] equal:expected];
    });
    
    it(@"finds max value", ^{
        NSDate *expected = [dateFormatter dateFromString:@"Mar 15, 2010"];
        
        NSDate *latestDate1;
        for (Transaction *transaction in transactions) {
            if (transaction.date == nil) { continue; }
            if (latestDate1 == nil) {
                latestDate1 = transaction.date;
            }
            if ([transaction.date compare:latestDate1] == NSOrderedDescending) {
                latestDate1 = transaction.date;
            }
        }
        [[latestDate1 should] equal:expected];
        
        NSDate *latestDate2 = [transactions valueForKeyPath:@"@max.date"];
        [[latestDate2 should] equal:expected];
    });
    
    it(@"finds min value", ^{
        NSDate *expected = [dateFormatter dateFromString:@"Dec 1, 2009"];
        
        NSDate *earliestDate1;
        for (Transaction *transaction in transactions) {
            if (transaction.date == nil) { continue; }
            if (earliestDate1 == nil) {
                earliestDate1 = transaction.date;
            }
            if ([transaction.date compare:earliestDate1] == NSOrderedAscending) {
                earliestDate1 = transaction.date;
            }
        }
        [[earliestDate1 should] equal:expected];
        
        NSDate *earliestDate2 = [transactions valueForKeyPath:@"@min.date"];
        [[earliestDate2 should] equal:expected];
    });

});

#pragma mark Object operators
describe(@"Object Operators", ^{
    it(@"returns unique property values in collection", ^{
        NSArray *expected = @[@"Green Power", @"Car Loan", @"General Cable"];
        int expectedCount = 3;
        
        NSMutableArray *payees1 = [NSMutableArray arrayWithCapacity:3];
        for (Transaction *transaction in transactions) {
            if (transaction.payee == nil) { continue; }
            if (![payees1 containsObject:transaction.payee]) {
                [payees1 addObject:transaction.payee];
            }
        }
        [[payees1 should] containObjectsInArray:expected];
        [[payees1 should] haveCountOf:expectedCount];
        
        NSArray *payees2 = [transactions valueForKeyPath:@"@distinctUnionOfObjects.payee"];
        [[payees2 should] containObjectsInArray:expected];
        [[payees2 should] haveCountOf:expectedCount];
    });
    
    it(@"returns all property values in collection", ^{
        int expectedCount = 8;
        
        NSMutableArray *payees1 = [NSMutableArray arrayWithCapacity:3];
        for (Transaction *transaction in transactions) {
            if (transaction.payee == nil) { continue; }
                [payees1 addObject:transaction.payee];
        }
        [[payees1 should] haveCountOf:expectedCount];
        [[[payees1 indexesOfObjectsPassingTest:^BOOL (id obj, NSUInteger idx, BOOL *stop){
            return obj == @"Green Power";
        }] should] haveCountOf:3];
        [[[payees1 indexesOfObjectsPassingTest:^BOOL (id obj, NSUInteger idx, BOOL *stop){
            return obj == @"Car Loan";
        }] should] haveCountOf:3];
        [[[payees1 indexesOfObjectsPassingTest:^BOOL (id obj, NSUInteger idx, BOOL *stop){
            return obj == @"General Cable";
        }] should] haveCountOf:2];

        
        NSArray *payees2 = [transactions valueForKeyPath:@"@unionOfObjects.payee"];
        [[payees2 should] haveCountOf:expectedCount];
        [[[payees2 indexesOfObjectsPassingTest:^BOOL (id obj, NSUInteger idx, BOOL *stop){
            return obj == @"Green Power";
        }] should] haveCountOf:3];
        [[[payees2 indexesOfObjectsPassingTest:^BOOL (id obj, NSUInteger idx, BOOL *stop){
            return obj == @"Car Loan";
        }] should] haveCountOf:3];
        [[[payees2 indexesOfObjectsPassingTest:^BOOL (id obj, NSUInteger idx, BOOL *stop){
            return obj == @"General Cable";
        }] should] haveCountOf:2];
    });
});

#pragma mark Array and set operators
describe(@"Array and set operators", ^{
    NSArray *listOfTransactionList = [NSArray arrayWithObjects:transactions, transactions, nil];
    
    it(@"returns unique property values in nested collection", ^{
        NSArray *expected = @[[NSNull null], @"Green Power", @"Car Loan", @"General Cable"];
        int expectedCount = 4;
        
        NSMutableArray *payees1 = [NSMutableArray arrayWithCapacity:4];
        for (NSArray *transactionList in listOfTransactionList) {
            for (Transaction *transaction in transactionList) {
                id object = (transaction.payee ? transaction.payee : [NSNull null] );
                if (![payees1 containsObject:object]) {
                    [payees1 addObject:object];
                }
            }
        }
        [[payees1 should] haveCountOf:expectedCount];
        [[payees1 should] containObjectsInArray:expected];
        
        NSArray *payees2 = [listOfTransactionList valueForKeyPath:@"@distinctUnionOfArrays.payee"];
        [[payees2 should] haveCountOf:expectedCount];
        [[payees2 should] containObjectsInArray:expected];
    });
    
    it(@"returns all property values in nested collection", ^{
        int expectedCount = 18;
        
        NSMutableArray *payees1 = [NSMutableArray arrayWithCapacity:18];
        for (NSArray *transactionList in listOfTransactionList) {
            for (Transaction *transaction in transactionList) {
                [payees1 addObject:(transaction.payee ? transaction.payee : [NSNull null] )];
            }
        }
        [[payees1 should] haveCountOf:expectedCount];
        [[[payees1 indexesOfObjectsPassingTest:^BOOL (id obj, NSUInteger idx, BOOL *stop){
            return obj == @"Green Power";
        }] should] haveCountOf:6];
        [[[payees1 indexesOfObjectsPassingTest:^BOOL (id obj, NSUInteger idx, BOOL *stop){
            return obj == @"Car Loan";
        }] should] haveCountOf:6];
        [[[payees1 indexesOfObjectsPassingTest:^BOOL (id obj, NSUInteger idx, BOOL *stop){
            return obj == @"General Cable";
        }] should] haveCountOf:4];
        [[[payees1 indexesOfObjectsPassingTest:^BOOL (id obj, NSUInteger idx, BOOL *stop){
            return obj == [NSNull null];
        }] should] haveCountOf:2];
        
        
        NSArray *payees2 = [listOfTransactionList valueForKeyPath:@"@unionOfArrays.payee"];
        [[payees2 should] haveCountOf:expectedCount];
        [[[payees2 indexesOfObjectsPassingTest:^BOOL (id obj, NSUInteger idx, BOOL *stop){
            return obj == @"Green Power";
        }] should] haveCountOf:6];
        [[[payees2 indexesOfObjectsPassingTest:^BOOL (id obj, NSUInteger idx, BOOL *stop){
            return obj == @"Car Loan";
        }] should] haveCountOf:6];
        [[[payees2 indexesOfObjectsPassingTest:^BOOL (id obj, NSUInteger idx, BOOL *stop){
            return obj == @"General Cable";
        }] should] haveCountOf:4];
        [[[payees2 indexesOfObjectsPassingTest:^BOOL (id obj, NSUInteger idx, BOOL *stop){
            return obj == [NSNull null];
        }] should] haveCountOf:2];
    });
});


SPEC_END