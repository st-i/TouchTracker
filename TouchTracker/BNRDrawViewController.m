//
//  BNRDrawViewController.m
//  TouchTracker
//
//  Created by iStef on 25.12.16.
//  Copyright © 2016 Stefanov. All rights reserved.
//

#import "BNRDrawViewController.h"
#import "BNRDrawView.h"

@implementation BNRDrawViewController

-(void)loadView
{
    self.view=[[BNRDrawView alloc]initWithFrame:CGRectZero];
}

@end
