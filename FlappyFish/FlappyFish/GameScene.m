//
//  GameScene.m
//  FlappyFish
//
//  Created by UMBLR on 2015/01/01.
//  Copyright (c) 2015年 raus0. All rights reserved.
//

#import "GameScene.h"

@interface GameScene () <SKPhysicsContactDelegate> {
    SKSpriteNode* _fish;
    SKColor* _seaColor;
    SKTexture* _stoneTexture1;
    SKTexture* _stoneTexture2;
    SKAction* _moveStonesAndRemove;
    SKNode* _moving;
    SKNode* _stones;
    BOOL _canRestart;
    SKLabelNode* _scoreLabelNode;
    NSInteger _score;
}
@end

@implementation GameScene

static const uint32_t fishCategory = 1 << 0;
static const uint32_t worldCategory = 1 << 1;
static const uint32_t stoneCategory = 1 << 2;
static const uint32_t scoreCategory = 1 << 3;

static NSInteger const kVerticalStoneGap = 100;

-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */
        
        _canRestart = NO;
        
        self.physicsWorld.gravity = CGVectorMake( 0.0, -2.0 );
        self.physicsWorld.contactDelegate = self;
        
        _seaColor = [SKColor colorWithRed:96.0/255.0 green:88.0/255.0 blue:248.0/255.0 alpha:1.0];
        [self setBackgroundColor:_seaColor];
        
        _moving = [SKNode node];
        [self addChild:_moving];
        
        _stones = [SKNode node];
        [_moving addChild:_stones];
        
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
        _fish.physicsBody.categoryBitMask = fishCategory;
        _fish.physicsBody.collisionBitMask = worldCategory | stoneCategory;
        _fish.physicsBody.contactTestBitMask = worldCategory | stoneCategory;
        
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
            [_moving addChild:sprite];
        }
        
        // Create coral
        
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
        dummy.physicsBody.categoryBitMask = worldCategory;
        [self addChild:dummy];
        
        // Create stones
        
        _stoneTexture1 = [SKTexture textureWithImageNamed:@"Stone1"];
        _stoneTexture1.filteringMode = SKTextureFilteringNearest;
        _stoneTexture2 = [SKTexture textureWithImageNamed:@"Stone2"];
        _stoneTexture2.filteringMode = SKTextureFilteringNearest;
        
        CGFloat distanceToMove = self.frame.size.width + 2 * _stoneTexture1.size.width;
        SKAction* moveStones = [SKAction moveByX:-distanceToMove y:0 duration:0.01 * distanceToMove];
        SKAction* removeStones = [SKAction removeFromParent];
        _moveStonesAndRemove = [SKAction sequence:@[moveStones, removeStones]];
        
        SKAction* spawn = [SKAction performSelector:@selector(spawnStones) onTarget:self];
        SKAction* delay = [SKAction waitForDuration:2.0];
        SKAction* spawnThenDelay = [SKAction sequence:@[spawn, delay]];
        SKAction* spawnThenDelayForever = [SKAction repeatActionForever:spawnThenDelay];
        [self runAction:spawnThenDelayForever];
        
        // Initialize label and create a label which holds the score
        _score = 0;
        _scoreLabelNode = [SKLabelNode labelNodeWithFontNamed:@"Chalkboard SE Bold"];
        _scoreLabelNode.position = CGPointMake( CGRectGetMidX( self.frame ), 3 * self.frame.size.height / 4 );
        _scoreLabelNode.zPosition = 100;
        _scoreLabelNode.text = [NSString stringWithFormat:@"%ld", (long)_score];
        [self addChild:_scoreLabelNode];
    }
    return self;
}

-(void)spawnStones {
    SKNode* stonePair = [SKNode node];
    stonePair.position = CGPointMake( self.frame.size.width + _stoneTexture1.size.width, 0 );
    stonePair.zPosition = -10;
    
    CGFloat y = arc4random() % (NSInteger)( self.frame.size.height / 3 );
    
    SKSpriteNode* stone1 = [SKSpriteNode spriteNodeWithTexture:_stoneTexture1];
    [stone1 setScale:2];
    stone1.position = CGPointMake( 0, y );
    stone1.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:stone1.size];
    stone1.physicsBody.dynamic = NO;
    stone1.physicsBody.categoryBitMask = stoneCategory;
    stone1.physicsBody.contactTestBitMask = fishCategory;
    
    [stonePair addChild:stone1];
    
    SKSpriteNode* stone2 = [SKSpriteNode spriteNodeWithTexture:_stoneTexture2];
    [stone2 setScale:2];
    stone2.position = CGPointMake( 0, y + stone1.size.height + kVerticalStoneGap );
    stone2.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:stone2.size];
    stone2.physicsBody.dynamic = NO;
    stone2.physicsBody.categoryBitMask = stoneCategory;
    stone2.physicsBody.contactTestBitMask = fishCategory;
    [stonePair addChild:stone2];
    
    SKNode* contactNode = [SKNode node];
    contactNode.position = CGPointMake( stone1.size.width + _fish.size.width / 2, CGRectGetMidY( self.frame ) );
    contactNode.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(stone2.size.width, self.frame.size.height)];
    contactNode.physicsBody.dynamic = NO;
    contactNode.physicsBody.categoryBitMask = scoreCategory;
    contactNode.physicsBody.contactTestBitMask = fishCategory;
    [stonePair addChild:contactNode];
    
    [stonePair runAction:_moveStonesAndRemove];
    
    [_stones addChild:stonePair];
}

-(void)resetScene {
    // Reset fish properties
    _fish.position = CGPointMake(self.frame.size.width / 4, CGRectGetMidY(self.frame));
    _fish.physicsBody.velocity = CGVectorMake( 0, 0 );
    _fish.physicsBody.collisionBitMask = worldCategory | stoneCategory;
    _fish.speed = 1.0;
    _fish.zRotation = 0.0;
    
    // Remove all existing stones
    [_stones removeAllChildren];
    
    // Reset _canRestart
    _canRestart = NO;
    
    // Restart animation
    _moving.speed = 1;
    
    // Reset score
    _score = 0;
    _scoreLabelNode.text = [NSString stringWithFormat:@"%ld", (long)_score];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
     if( _moving.speed > 0 ) {
         /*_fish.physicsBody.velocity = CGVectorMake(0, 0.5);*/
         [_fish.physicsBody applyImpulse:CGVectorMake(0, 2)];
    } else if( _canRestart ) {
        [self resetScene];
    }
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
    if( _moving.speed > 0 ) {
    _fish.zRotation = clamp( -1, 0.5, _fish.physicsBody.velocity.dy * ( _fish.physicsBody.velocity.dy < 0 ? 0.001 : 0.002 ) );
    }
}

- (void)didBeginContact:(SKPhysicsContact *)contact {
    if( _moving.speed > 0 ) {
        if( ( contact.bodyA.categoryBitMask & scoreCategory ) == scoreCategory || ( contact.bodyB.categoryBitMask & scoreCategory ) == scoreCategory ) {
            // Fish has contact with score entity
            
            _score++;
            _scoreLabelNode.text = [NSString stringWithFormat:@"%ld", (long)_score];
            
            // Add a little visual feedback for the score increment
            [_scoreLabelNode runAction:[SKAction sequence:@[[SKAction scaleTo:1.5 duration:0.1], [SKAction scaleTo:1.0 duration:0.1]]]];
        } else {
            // Fish has collided with world
            
            _moving.speed = 0;
            
            _fish.physicsBody.collisionBitMask = worldCategory;
            
            [_fish runAction:[SKAction rotateByAngle:M_PI * _fish.position.y * 0.01 duration:_fish.position.y * 0.003] completion:^{
                _fish.speed = 0;
            }];
            
            // Flash background if contact is detected
            [self removeActionForKey:@"flash"];
            [self runAction:[SKAction sequence:@[[SKAction repeatAction:[SKAction sequence:@[[SKAction runBlock:^{
                self.backgroundColor = [SKColor yellowColor];
            }], [SKAction waitForDuration:0.05], [SKAction runBlock:^{
                self.backgroundColor = _seaColor;
            }], [SKAction waitForDuration:0.05]]] count:4], [SKAction runBlock:^{
                _canRestart = YES;
            }]]] withKey:@"flash"];
        }
    }
}

@end
