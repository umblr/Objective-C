//
//  GameScene.m
//  FlappyFish
//
//  Created by UMBLR on 2015/01/01.
//  Copyright (c) 2015年 raus0. All rights reserved.
//

#import "GameScene.h"

@interface GameScene () {
    SKSpriteNode* _fish;
    SKColor* _seaColor;
}
@end

@implementation GameScene

static NSInteger const kVerticalStoneGap = 100;

-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */
        
        self.physicsWorld.gravity = CGVectorMake( 0.0, -2.0 );
        
        _seaColor = [SKColor colorWithRed:96.0/255.0 green:88.0/255.0 blue:248.0/255.0 alpha:1.0];
        [self setBackgroundColor:_seaColor];
        
        SKTexture* fishTexture1 = [SKTexture textureWithImageNamed:@"Fish1"];
        fishTexture1.filteringMode = SKTextureFilteringNearest;
        SKTexture* fishTexture2 = [SKTexture textureWithImageNamed:@"Fish2"];
        fishTexture2.filteringMode = SKTextureFilteringNearest;
        
        SKAction* flap = [SKAction repeatActionForever:[SKAction animateWithTextures:@[fishTexture1, fishTexture2] timePerFrame:0.2]];
   
        _fish = [SKSpriteNode spriteNodeWithTexture:fishTexture1];
        [_fish setScale:2.0];
        _fish.position = CGPointMake(self.frame.size.width / 4, CGRectGetMidY(self.frame));
        [_fish runAction:flap];
        
        _fish.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:_fish.size.height / 2];
        _fish.physicsBody.dynamic = YES;
        _fish.physicsBody.allowsRotation = NO;
        
        [self addChild:_fish];
        
        // Create ground
        
        SKTexture* groundTexture = [SKTexture textureWithImageNamed:@"Ground"];
        groundTexture.filteringMode = SKTextureFilteringNearest;
        
        SKAction* moveGroundSprite = [SKAction moveByX:-groundTexture.size.width*2 y:0 duration:0.02 * groundTexture.size.width*2];
        SKAction* resetGroundSprite = [SKAction moveByX:groundTexture.size.width*2 y:0 duration:0];
        SKAction* moveGroundSpritesForever = [SKAction repeatActionForever:[SKAction sequence:@[moveGroundSprite, resetGroundSprite]]];
        
        for( int i = 0; i < 2 + self.frame.size.width / ( groundTexture.size.width * 2 ); ++i ) {
            SKSpriteNode* sprite = [SKSpriteNode spriteNodeWithTexture:groundTexture];
            [sprite setScale:2.0];
            sprite.position = CGPointMake(i * sprite.size.width, sprite.size.height / 2);
            [sprite runAction:moveGroundSpritesForever];
            [self addChild:sprite];
        }
        
        // Create Coral
        
        SKTexture* coralTexture = [SKTexture textureWithImageNamed:@"Coral"];
        coralTexture.filteringMode = SKTextureFilteringNearest;
        
        
        SKAction* moveCoralSprite = [SKAction moveByX:-coralTexture.size.width*2 y:0 duration:0.1 * coralTexture.size.width*2];
        SKAction* resetCoralSprite = [SKAction moveByX:coralTexture.size.width*2 y:0 duration:0];
        SKAction* moveCoralSpritesForever = [SKAction repeatActionForever:[SKAction sequence:@[moveCoralSprite, resetCoralSprite]]];
        
        for( int i = 0; i < 2 + self.frame.size.width / ( coralTexture.size.width * 2 ); ++i ) {
            SKSpriteNode* sprite = [SKSpriteNode spriteNodeWithTexture:coralTexture];
            [sprite setScale:2.0];
            sprite.zPosition = -20;
            sprite.position = CGPointMake(i * sprite.size.width, sprite.size.height / 2 + groundTexture.size.height * 2);
            [sprite runAction:moveCoralSpritesForever];
            [self addChild:sprite];
        }
        
        // Create ground physics container
        
        SKNode* dummy = [SKNode node];
        dummy.position = CGPointMake(0, groundTexture.size.height);
        dummy.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(self.frame.size.width, groundTexture.size.height * 2)];
        dummy.physicsBody.dynamic = NO;
        [self addChild:dummy];
        
        // Create stones
        
        SKTexture* _stoneTexture1 = [SKTexture textureWithImageNamed:@"Stone1"];
        _stoneTexture1.filteringMode = SKTextureFilteringNearest;
        SKTexture* _stoneTexture2 = [SKTexture textureWithImageNamed:@"Stone2"];
        _stoneTexture2.filteringMode = SKTextureFilteringNearest;
        
        SKNode* stonePair = [SKNode node];
        stonePair.position = CGPointMake( self.frame.size.width + _stoneTexture1.size.width * 2, 0 );
        stonePair.zPosition = -10;
        
        CGFloat y = arc4random() % (NSInteger)( self.frame.size.height / 3 );
        
        SKSpriteNode* stone1 = [SKSpriteNode spriteNodeWithTexture:_stoneTexture1];
        [stone1 setScale:2];
        stone1.position = CGPointMake( 0, y );
        stone1.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:stone1.size];
        stone1.physicsBody.dynamic = NO;
        [stonePair addChild:stone1];
        
        SKSpriteNode* stone2 = [SKSpriteNode spriteNodeWithTexture:_stoneTexture2];
        [stone2 setScale:2];
        stone2.position = CGPointMake( 0, y + stone1.size.height + kVerticalStoneGap );
        stone2.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:stone2.size];
        stone2.physicsBody.dynamic = NO;
        [stonePair addChild:stone2];
        
        SKAction* movePipes = [SKAction repeatActionForever:[SKAction moveByX:-1 y:0 duration:0.02]];
        [stonePair runAction:movePipes];
        
        [self addChild:stonePair];
        
    }
    return self;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    /*_fish.physicsBody.velocity = CGVectorMake(0, 0.5);*/
    [_fish.physicsBody applyImpulse:CGVectorMake(0, 2)];
}

CGFloat clamp(CGFloat min, CGFloat max, CGFloat value) {
    if( value > max ) {
        return max;
    } else if( value < min ) {
        return min;
    } else {
        return value;
    }
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
    _fish.zRotation = clamp( -1, 0.5, _fish.physicsBody.velocity.dy * ( _fish.physicsBody.velocity.dy < 0 ? 0.001 : 0.002 ) );
}

@end
