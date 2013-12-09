//
//  GameScreen.m
//  LoveLetter
//
//  Created by Fisher on 12/9/13.
//  Copyright (c) 2013 Threadbare Games. All rights reserved.
//

#import "GameScreen.h"

#import "PlayerSprite.h"
#import "Card.h"
#import "Constants.h"
#import "GameModel.h"
#import "LLPlayer.h"
#import "Deck.h"

@implementation GameScreen

// Helper class method that creates a Scene with the HelloWorldLayer as the only child.
+(CCScene*)scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	GameScreen *layer = [GameScreen node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

-(id)init
{
    if (self = [super init])
    {
        cardButtonOldPos = ccp(WIN_CENTER.x + 100, 150);
        cardButtonNewPos = ccp(WIN_CENTER.x - 100, 150);
        chosenCardPos    = ccp(WIN_CENTER.x, WIN_CENTER.y + 100);
        cancelButtonPos  = ccp(WIN_CENTER.x - 120, 300);
        playButtonPos    = ccp(WIN_CENTER.x + 120, 300);
    }
    return self;
}

-(void)onEnterTransitionDidFinish
{
    [super onEnterTransitionDidFinish];
    
    [[GameModel sharedInstance] startRound];
    
    [self layoutPlayerSprites];
    
    CCLabelBMFont* labelInHand = [CCLabelBMFont labelWithString:@"In Hand" fntFile:FONT_BIG];
    [labelInHand setPosition:ccp(WIN_CENTER.x, 190)];
    [self addChild:labelInHand];
    
    CCLabelBMFont* labelPlayed = [CCLabelBMFont labelWithString:@"Played" fntFile:FONT_BIG];
    [labelPlayed setAnchorPoint:CGPointZero];
    [labelPlayed setPosition:ccp(10, 340)];
    [self addChild:labelPlayed];
    [self updateCardsUI];
    
    [self layoutDrawDeck];
    drawDeckCount = [CCLabelBMFont labelWithString:[NSString stringWithFormat:@"%i", 0] fntFile:FONT_BIG];
    [self addChild:drawDeckCount];
    [self updateDrawDeckCardCount];
    [[GameModel sharedInstance] addObserver:self forKeyPath:@"deck" options:0 context:nil];
}

-(void)onExit
{
    [super onExit];
    
    [[[GameModel sharedInstance] deck] removeObserver:self forKeyPath:@"deck"];
}

-(void)layoutPlayerSprites
{
    CGPoint startingPosition = ccp(0, 900);
    CGPoint offset = ccp(0, -200);
    
    int counter = 0;
    CCLOG(@"game model contains %d players", [GameModel sharedInstance].players.count);
    for (LLPlayer* player in [GameModel sharedInstance].players)
    {
        PlayerSprite* playerSprite = [[PlayerSprite alloc] initWithPlayer:player];
        if (player.isAI)
        {
            [playerSprite setPosition:ccpAdd(startingPosition, ccpMult(offset, counter))];
            [self addChild:playerSprite];
            CCLOG(@"created sprite for ai player %@", player.playerid);
            counter++;
        }
        else
        {
            [playerSprite setPosition:ccp(0, 300)];
            [self addChild:playerSprite];
            CCLOG(@"created sprite for human player %@", player.playerid);
        }
    }
}

-(void)updateCardsUI
{
    [self.cardButtonNew removeFromParentAndCleanup:YES];
    [self.cardButtonOld removeFromParentAndCleanup:YES];
    
    LLPlayer* humanPlayer;
    for (LLPlayer* player in [GameModel sharedInstance].players)
    {
        if (!player.isAI)
        {
            humanPlayer = player;
        }
    }
    
    if (humanPlayer.cardsInHand.count > 1)
    {
        Card* new = (Card*)[humanPlayer.cardsInHand objectAtIndex:1];
        self.cardButtonNew = [self createBadgeButton:new];
        [self.cardButtonNew setPosition:cardButtonNewPos];
        [self addChild:self.cardButtonNew];
    }
    
    if (humanPlayer.cardsInHand.count > 0)
    {
        Card* old = (Card*)[humanPlayer.cardsInHand objectAtIndex:0];
        self.cardButtonOld = [self createBadgeButton:old];
        [self.cardButtonOld setPosition:cardButtonOldPos];
        [self addChild:self.cardButtonOld];
    }
}

-(void)layoutDrawDeck
{
    // Grab card sprites
    const int cardStackCount = 3;
    
    for (int i = 0; i < cardStackCount; i++)
    {
        CCSprite* card = [Deck getBackCardSprite];
        card.scale = 0.2f;
        float pointX = self.contentSize.width - (card.contentSize.width * card.scale / 2.0f) - 20.0f + ((float)i * 5.0f);
        float pointY = (card.contentSize.height * card.scale / 2.0f) + 20.0f - ((float)i * 5.0f);
        CGPoint cardPos = ccp(pointX, pointY);
        card.position = cardPos;
        
        [self addChild:card];
    }
}

-(void)updateDrawDeckCardCount
{
    int cardCount = [[GameModel sharedInstance] deck].cards.count;
    float cardCountScale = 2.0f;
    [drawDeckCount setString:[NSString stringWithFormat:@"%i", cardCount]];
    drawDeckCount.scale = cardCountScale;
    float pointX = self.contentSize.width - (drawDeckCount.contentSize.width * drawDeckCount.scale / 2.0f) - 40.0f;
    float pointY = (drawDeckCount.contentSize.height * drawDeckCount.scale / 2.0f) + 20.0f;
    CGPoint countPos = ccp(pointX, pointY);
    
    drawDeckCount.position = countPos;
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"deck"])
    {
        [self updateDrawDeckCardCount];
    }
}

-(CCMenu*)createBadgeButton:(Card*)card
{
    CCMenuItemSprite* normal = [CCMenuItemSprite itemWithNormalSprite:[card createBadgeSpriteNormal]
                                                       selectedSprite:[card createBadgeSpriteNormal]
                                                                block:^(id sender) {
                                                                    //
                                                                }];
    
    CCMenuItemSprite* selected = [CCMenuItemSprite itemWithNormalSprite:[card createBadgeSpriteSelected]
                                                         selectedSprite:[card createBadgeSpriteSelected]
                                                                  block:^(id sender) {
                                                                      //
                                                                }];
    
    
    CCMenuItemToggle* toggle = [CCMenuItemToggle itemWithItems:
                                [NSArray arrayWithObjects:normal, selected, nil]
                                                         block:^(CCMenuItemToggle* sender) {
                                                         [self.chosenCardSprite removeFromParentAndCleanup:YES];
                                                         if (sender.selectedItem == selected)
                                                         {
                                                             self.chosenCardSprite = [card cardSprite];
                                                             [self.chosenCardSprite setPosition:chosenCardPos];
                                                             [self addChild:self.chosenCardSprite];
                                                             
                                                             CCMenu* cancelButton = [self cancelButton];
                                                             [cancelButton setPosition:[self.chosenCardSprite convertToNodeSpace:cancelButtonPos]];
                                                             [self.chosenCardSprite addChild:cancelButton];
                                                             
                                                             CCMenu* playButton = [self playButton];
                                                             [playButton setPosition:[self.chosenCardSprite convertToNodeSpace:playButtonPos]];
                                                             [self.chosenCardSprite addChild:playButton];
                                                         }
                                                     }];
    return [CCMenu menuWithItems:toggle, nil];
}

-(CCMenu*)cancelButton
{
    CCSprite* normal     = [self buttonSprite:@"Cancel"];
    CCSprite* selected   = [self buttonSprite:@"Cancel"];
    
    CCMenuItemSprite* button = [CCMenuItemSprite itemWithNormalSprite:normal
                                                       selectedSprite:selected
                                                                block:^(id sender) {
                                                                    CCLOG(@"cancel button clicked");
                                                                }];
    return [CCMenu menuWithItems:button, nil];
}

-(CCMenu*)playButton
{
    CCSprite* normal     = [self buttonSprite:@"Play"];
    CCSprite* selected   = [self buttonSprite:@"Play"];
    
    CCMenuItemSprite* button = [CCMenuItemSprite itemWithNormalSprite:normal
                                                       selectedSprite:selected
                                                                block:^(id sender) {
                                                                    CCLOG(@"play button clicked");
                                                                }];
    return [CCMenu menuWithItems:button, nil];
}

-(CCSprite*)buttonSprite:(NSString*)text
{
    CCSprite* buttonBG   = [CCSprite spriteWithFile:@"button.png"];
    [buttonBG setScale:0.5f];
    CCLabelBMFont* label = [CCLabelBMFont labelWithString:text fntFile:FONT_BIG];
    
    CCSprite* sprite     = [CCSprite node];
    [sprite setScale:2.0f];
    [sprite addChild:buttonBG];
    [sprite addChild:label];
    return sprite;
}


@end
