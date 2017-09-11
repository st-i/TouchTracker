//
//  BNRDrawView.m
//  TouchTracker
//
//  Created by iStef on 25.12.16.
//  Copyright © 2016 Stefanov. All rights reserved.
//

#import "BNRDrawView.h"
#import "BNRLine.h"

@interface BNRDrawView () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIPanGestureRecognizer *moveRecognizer;
//@property (nonatomic, strong) BNRLine *currentLine;
@property (nonatomic, strong) NSMutableDictionary *linesInProgress;
@property (nonatomic, strong) NSMutableArray *finishedLines;
@property (nonatomic, weak) BNRLine *selectedLine;

@end

@implementation BNRDrawView

-(instancetype)initWithFrame:(CGRect)r
{
    self=[super initWithFrame:r];
    
    if (self) {
        self.linesInProgress=[[NSMutableDictionary alloc]init];
        self.finishedLines=[[NSMutableArray alloc]init];
        self.backgroundColor=[UIColor grayColor];
        self.multipleTouchEnabled=YES;
        
        UITapGestureRecognizer *doubleTapRecognizer=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(doubleTap:)];
        doubleTapRecognizer.numberOfTapsRequired=2;
        doubleTapRecognizer.delaysTouchesBegan=YES;
        [self addGestureRecognizer:doubleTapRecognizer];
        
        UITapGestureRecognizer *tapRecognizer=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tap:)];
        tapRecognizer.delaysTouchesBegan=YES;
        [tapRecognizer requireGestureRecognizerToFail:doubleTapRecognizer];
        [self addGestureRecognizer:tapRecognizer];
        
        UILongPressGestureRecognizer *pressRecognizer=[[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(longPress:)];
        [self addGestureRecognizer:pressRecognizer];
        
        self.moveRecognizer=[[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(moveLine:)];
        self.moveRecognizer.delegate=self;
        self.moveRecognizer.cancelsTouchesInView=NO;
        [self addGestureRecognizer:self.moveRecognizer];
    }
    
    return self;
}

/*-(int)numberOfLines
{
    int count=0;
    
    //check that they are non-nil before we add their counts
    if (self.linesInProgress && self.finishedLines) {
        count=[self.linesInProgress count]+[self.finishedLines count];
    }
    return count;
}*/

-(void)moveLine:(UIPanGestureRecognizer *)gr
{
    //if we have not selected a line, we do not do anything here
    if (!self.selectedLine) {
        return;
    }
    
    //when the pan recognizer changes its position...
    if (gr.state==UIGestureRecognizerStateChanged) {
        //how far has the pan moved?
        CGPoint translation=[gr translationInView:self];
        
        //add the translation to the current beginning and end points of the line
        CGPoint begin=self.selectedLine.begin;
        CGPoint end=self.selectedLine.end;
        
        begin.x+=translation.x;
        end.x+=translation.x;
        begin.y+=translation.y;
        end.y+=translation.y;
        
        //set the new beginning and end points of the line
        self.selectedLine.begin=begin;
        self.selectedLine.end=end;
        
        //redraw the screen
        [self setNeedsDisplay];
        
        [gr setTranslation:CGPointZero inView:self];
    }
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(nonnull UIGestureRecognizer *)otherGestureRecognizer
{
    if (gestureRecognizer==self.moveRecognizer) {
        return YES;
    }
    return NO;
}

-(void)longPress:(UIGestureRecognizer *)gr
{
    [[UIMenuController sharedMenuController]setMenuVisible:NO animated:YES];
    
    if (gr.state==UIGestureRecognizerStateBegan) {
        CGPoint point=[gr locationInView:self];
        self.selectedLine=[self lineAtPoint:point];
        
        if (self.selectedLine) {
            [self.linesInProgress removeAllObjects];
        }
    }else if (gr.state==UIGestureRecognizerStateEnded){
            self.selectedLine=nil;
    }
    [self setNeedsDisplay];
}

-(BNRLine *)lineAtPoint:(CGPoint)p
{
    //find a line close to p
    for (BNRLine *l in self.finishedLines){
        CGPoint start=l.begin;
        CGPoint end=l.end;
        
        //check a few points on the line
        for (float t=0.0; t<1.0; t+=0.05) {
            float x=start.x+t*(end.x-start.x);
            float y=start.y+t*(end.y-start.y);
            
            //if the tapped line is within 20 points, let's return this line
            if (hypot(x-p.x, y-p.y)<20) {
                return l;
            }
        }
    }
    //if nothing is close enough to the tapped point, then we did not select a line
    return nil;
}

-(BOOL)canBecomeFirstResponder
{
    return YES;
}

-(void)tap:(UIGestureRecognizer *)gr
{
    NSLog(@"Recognized tap");
    
    CGPoint touch=[gr locationInView:self];
    self.selectedLine=[self lineAtPoint:touch];
    
    if (self.selectedLine) {
        
        //make ourselves the target of menu item action messages
        [self becomeFirstResponder];
        
        //grab the menu controller
        UIMenuController *menu=[UIMenuController sharedMenuController];
        
        //create a new "Delete" UIMenuItem
        UIMenuItem *deleteItem=[[UIMenuItem alloc]initWithTitle:@"Delete" action:@selector(deleteLine:)];
        menu.menuItems=@[deleteItem];
        
        //tell the menu where it should come from and show it
        [menu setTargetRect:CGRectMake(touch.x, touch.y, 2, 2) inView:self];
        [menu setMenuVisible:YES animated:YES];
    }else{
        //hide the menu if no line is selected
        [[UIMenuController sharedMenuController]setMenuVisible:NO animated:YES];
    }
    [self setNeedsDisplay];
}

-(void)deleteLine:(id)sender
{
    //remove the selected line from the list of _finishedLines
    [self.finishedLines removeObject:self.selectedLine];
    
    //redraw everything
    [self setNeedsDisplay];
}

-(void)doubleTap:(UIGestureRecognizer *)gr
{
    NSLog(@"Recognized double tap");
    
    [self.linesInProgress removeAllObjects];
    [self.finishedLines removeAllObjects];
    
    
    [self setNeedsDisplay];
}

-(void)strokeLine:(BNRLine *)line
{
    UIBezierPath *bp=[UIBezierPath bezierPath];
    bp.lineWidth=10;
    bp.lineCapStyle=kCGLineCapRound;
    
    [bp moveToPoint:line.begin];
    [bp addLineToPoint:line.end];
    [bp stroke];
}

-(void)drawRect:(CGRect)rect
{
    //draw finished lines in black
    [[UIColor blackColor]set];
    for (BNRLine *line in self.finishedLines) {
        [self strokeLine:line];
    }
    
    [[UIColor redColor]set];
    for (NSValue *key in self.linesInProgress) {
        [self strokeLine:self.linesInProgress[key]];
    }
    
    /*if (self.currentLine) {
        //if there is a line currently being drawn, do it in red
        [[UIColor redColor]set];
        [self strokeLine:self.currentLine];
    }*/
    
    if (self.selectedLine) {
        [[UIColor greenColor]set];
        [self strokeLine:self.selectedLine];
    }
    
    /*float f=0.0;
    for (int i=0; i<1000000; i++) {
        f=f+sin(sin(sin(time(NULL)+i)));
    }
    NSLog(@"f=%f", f);*/
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    //let's put to a log the statement to see the order of events
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
    for (UITouch *t in touches) {
        CGPoint location=[t locationInView:self];
        
        BNRLine *line=[[BNRLine alloc]init];
        line.begin=location;
        line.end=location;
        
        NSValue *key=[NSValue valueWithNonretainedObject:t];
        self.linesInProgress[key]=line;
    }
    
    /*UITouch *t=[touches anyObject];
    
    //get location of the touch in view's coordinate system
    CGPoint location=[t locationInView:self];
    self.currentLine=[[BNRLine alloc]init];
    self.currentLine.begin=location;
    self.currentLine.end=location;*/
    
    [self setNeedsDisplay];
}

-(void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    //let's put to a log the statement to see the order of events
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
    for (UITouch *t in touches) {
        NSValue *key=[NSValue valueWithNonretainedObject:t];
        BNRLine *line=self.linesInProgress[key];
        
        line.end=[t locationInView:self];
    }
    
    /*UITouch *t=[touches anyObject];
    
    CGPoint location=[t locationInView:self];
    
    self.currentLine.end=location;*/
    
    [self setNeedsDisplay];
}

-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    //let's put to a log the statement to see the order of events
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
    for (UITouch *t in touches) {
        NSValue *key=[NSValue valueWithNonretainedObject:t];
        BNRLine *line=self.linesInProgress[key];
        
        [self.finishedLines addObject:line];
        [self.linesInProgress removeObjectForKey:key];
}
    
    /*[self.finishedLines addObject:self.currentLine];
    self.currentLine=nil;*/
    
    [self setNeedsDisplay];
}

-(void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    //let's put to a log the statement to see the order of events
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
    for (UITouch *t in touches) {
        NSValue *key=[NSValue valueWithNonretainedObject:t];
        [self.linesInProgress removeObjectForKey:key];
    }
    
    [self setNeedsDisplay];
}

@end
