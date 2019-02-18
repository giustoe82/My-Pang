//
//  GameScene.swift
//  My Pang
//
//  Created by Marco Giustozzi on 2019-01-21.
//  Copyright © 2019 marcog. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    
    // MARK:- VAR DECLARATION
    
    //Sprites
    var player: SKSpriteNode?
    var ground: SKSpriteNode?
    var left: SKSpriteNode?
    var right: SKSpriteNode?
    var shoot: SKSpriteNode?
    var leftWall: SKSpriteNode?
    var rightWall: SKSpriteNode?
    var cloud: SKSpriteNode?
    var background = SKSpriteNode(imageNamed: "background")
    var replayButton: SKSpriteNode?
    
    //Animations settings
    private var foxWalkingFrames: [SKTexture] = []
    private var baloonHitFrames: [SKTexture] = []
    private var bombHitFrames: [SKTexture] = []
    
    
    //Objects Spawn Timer
    var baloonTimer: Timer?
    var bombTimer: Timer?
    var cloudTimer: Timer?
    
    //UI
    var score = 0
    var scoreLabel: SKLabelNode?
    var lives = 2
    var livesLabel: SKLabelNode?
    var yourScoreLabel: SKLabelNode?
    var pointsLabel: SKLabelNode?
    var floatingPointsLabel: SKLabelNode?
    
    //collision identifiers
    let playerCategory: UInt32 = 0x1 << 1
    let baloonCategory: UInt32 = 0x1 << 2
    let bombCategory: UInt32 = 0x1 << 3
    let boundsCategory: UInt32 = 0x1 << 4
    let arrowCategory: UInt32 = 0x1 << 5
    let cloudCategory: UInt32 = 0x1 << 6
    
    //Game difficulty
    var baloonTimeInterval: Double = 1.2
    var bombTimeInterval: Double = 4
    var levelCounter: Int = 0
    var levelLabel: SKLabelNode?
    
    
    
    // MARK:- Settings at start
   
    override func didMove(to view: SKView) {
        
        self.view?.isMultipleTouchEnabled = true
        //Collision delegate
        physicsWorld.contactDelegate = self
        
        //Setup
        background.position = CGPoint(x: 0, y: 0)
        background.size = (scene?.size)!
        addChild(background)
        background.zPosition = -1
        scoreLabel = childNode(withName: "scoreLabel") as? SKLabelNode
        scoreLabel?.text = "SCORE        0"
        scoreLabel?.zPosition = 10
        livesLabel = childNode(withName: "livesLabel") as? SKLabelNode
        livesLabel?.text = "LIVES  "+"\(lives)"
        
        
        // Sprites
        right = childNode(withName: "buttonRight") as? SKSpriteNode
        right?.zPosition = 5
        left = childNode(withName: "buttonLeft") as? SKSpriteNode
        left?.zPosition = 5
        shoot = childNode(withName: "shoot") as? SKSpriteNode
        shoot?.zPosition = 5
        buildFox()
        getBaloonHitFrames()
        getBombHitFrames()
        
        
        // Baloon Bomb Cloud Spawn
        startTimers(baloonTimeInterval: baloonTimeInterval, bombTimeInterval: bombTimeInterval)
        cloudTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true, block: {
            timer in
            self.createCloud()
        })
        //Music
        let backgroundMusic = SKAudioNode(fileNamed: "MyPangSoundtrack.mp3")
        backgroundMusic.autoplayLooped = true
        addChild(backgroundMusic)
    }
    
   
    
    // MARK:- Input and events
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            let touches = self.atPoint(location)
    
            if (touches.name == "buttonRight") {
                player?.removeAction(forKey: "buttonLeft")
                movePlayer(moveBy: 1000, forTheKey: "buttonRight")
            }
            if (touches.name == "buttonLeft") {
                player?.removeAction(forKey: "buttonRight")
                movePlayer(moveBy: -1000, forTheKey: "buttonLeft")
            }
            if (touches.name == "shoot") {
                createArrow()
            }
            if (touches.name == "shoot" && touches.name == "buttonRight") {
                player?.removeAction(forKey: "buttonLeft")
                movePlayer(moveBy: 1000, forTheKey: "buttonRight")
                createArrow()
            }
            if (touches.name == "shoot" && touches.name == "buttonLeft") {
                player?.removeAction(forKey: "buttonRight")
                movePlayer(moveBy: -1000, forTheKey: "buttonLeft")
                createArrow()
            }
            if touches.name == "replay" {
                for child in self.children {
                    if child.name == "myBaloon" || child.name == "myBomb"  {
                        child.removeFromParent()
                    }
                }
                score = 0
                lives = 2
                levelCounter = 0
                baloonTimeInterval = 1
                bombTimeInterval = 4
                livesLabel?.text = "LIVES  "+"\(lives)"
                scoreLabel?.text = "SCORE        " + "\(score)"
                replayButton?.removeFromParent()
                yourScoreLabel?.removeFromParent()
                pointsLabel?.removeFromParent()
                scene?.isPaused = false
                startTimers(baloonTimeInterval: baloonTimeInterval, bombTimeInterval: bombTimeInterval)
                cloudTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true, block: {
                    timer in
                    self.createCloud()
                })
            }            
        }
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            let touches = self.atPoint(location)

            
            if (touches.name == "buttonRight") {
                player?.removeAction(forKey: "buttonRight")
                player?.removeAction(forKey: "walkingFox")
            } else if (touches.name == "buttonLeft") {
                player?.removeAction(forKey: "buttonLeft")
                player?.removeAction(forKey: "walkingFox")
            } else if (touches.name == "shoot"){
                
            }
        }
        
    }
    
    
    
    // MARK:- Contacts and score/level label update
    
    
    func didBegin(_ contact: SKPhysicsContact) {
        
        if contact.bodyA.categoryBitMask == baloonCategory, contact.bodyB.categoryBitMask == arrowCategory {
            score += 20
            baloonHit(sprite: contact.bodyA.node!, points: 3)
            contact.bodyB.node?.removeFromParent()
            
        }
        if contact.bodyB.categoryBitMask == baloonCategory, contact.bodyA.categoryBitMask == arrowCategory {
            score += 20
            baloonHit(sprite: contact.bodyB.node!, points: 3)
            contact.bodyA.node?.removeFromParent()
        }
        if contact.bodyA.categoryBitMask == bombCategory, contact.bodyB.categoryBitMask == arrowCategory  {
            score += 5
            bombHit(sprite: contact.bodyA.node!, points: 5)
            contact.bodyB.node?.removeFromParent()
        }
        if contact.bodyB.categoryBitMask == bombCategory, contact.bodyA.categoryBitMask == arrowCategory {
            score += 5
            contact.bodyA.node?.removeFromParent()
            bombHit(sprite: contact.bodyB.node!, points: 5)
            
        }
        if contact.bodyA.categoryBitMask == playerCategory, contact.bodyB.categoryBitMask == baloonCategory {
        }
        if contact.bodyA.categoryBitMask == baloonCategory, contact.bodyB.categoryBitMask == playerCategory {
        }
        if contact.bodyA.categoryBitMask == playerCategory, contact.bodyB.categoryBitMask == bombCategory {
            score -= 10
            bombHit(sprite: contact.bodyB.node!, points: -10)
            lives -= 1
    
        }
        if contact.bodyA.categoryBitMask == bombCategory, contact.bodyB.categoryBitMask == playerCategory {
            lives -= 1
            score -= 10
            bombHit(sprite: contact.bodyA.node!, points: -10)
           
        }
        scoreLabel?.text = "SCORE        " + "\(score)"
        if lives != -1 {
            livesLabel?.text = "LIVES  "+"\(lives)"
        } else {
            gameOver(score: score)
        }
        
        if score > 15, levelCounter == 0 {
            levelCounter += 1
            levelUp(level : levelCounter)
        }
        if score > 50, levelCounter == 1 {
            levelCounter += 1
            levelUp(level : levelCounter)
        }
        if score > 120, levelCounter == 2 {
            levelCounter += 1
            levelUp(level : levelCounter)
        }
        if score > 200, levelCounter == 3 {
            levelCounter += 1
            levelUp(level : levelCounter)
        }
        if score > 300, levelCounter == 4 {
            levelCounter += 1
            levelUp(level : levelCounter)
        }
    }
    
    
    // MARK:- Sprites creation
    func createBaloon() {
        let baloons = ["balloon1", "balloon2", "balloon3", "balloon4", "balloon5"]
        let selector = rng(max: 5, min: 0)
        let baloon = SKSpriteNode(imageNamed: baloons[Int(selector - 1)])
        baloon.name = "myBaloon"
        baloon.zPosition = 4
        baloon.physicsBody = SKPhysicsBody(rectangleOf: baloon.size)
        baloon.physicsBody?.affectedByGravity = false
        baloon.physicsBody?.categoryBitMask = baloonCategory
        baloon.physicsBody?.contactTestBitMask = arrowCategory
        baloon.physicsBody?.collisionBitMask = 0
        addChild(baloon)
        
        spawnBaloon(sprite: baloon)
        
        
    }
    
    func getBaloonHitFrames() {
        let baloonAnimatedAtlas = SKTextureAtlas(named: "baloon")
        var exFrames: [SKTexture] = []
        let explosionTextureName = "balloon_explode"
        exFrames.append(baloonAnimatedAtlas.textureNamed(explosionTextureName))
        
        baloonHitFrames = exFrames
    }
    
    func baloonHit(sprite: SKNode, points: Int) {
        sprite.removeAllActions()
        sprite.physicsBody = nil
        let popSound = SKAction.playSoundFileNamed("pop.mp3", waitForCompletion: false)
        let explode = SKAction.animate(with: baloonHitFrames,
                                       timePerFrame: 0.1,
                                       resize: false,
                                       restore: true)
        let seq = SKAction.sequence([popSound, explode, SKAction.removeFromParent()])
        
        sprite.run(seq, withKey: "baloonHit")
        
        showPoints(sprite: sprite, points: points)
        
    }
    
    func createBomb() {
        let bomb = SKSpriteNode(imageNamed: "bomb")
        bomb.name = "myBomb"
        bomb.zPosition = 4
        bomb.physicsBody = SKPhysicsBody(circleOfRadius: (bomb.size.width / 2) - (bomb.size.width / 8))
        bomb.physicsBody?.usesPreciseCollisionDetection = true
        bomb.physicsBody?.affectedByGravity = false
        bomb.physicsBody?.categoryBitMask = bombCategory
        bomb.physicsBody?.contactTestBitMask = bombCategory
        bomb.physicsBody?.collisionBitMask = 0
        addChild(bomb)
        spawnBomb(sprite: bomb)
    }
    
    func getBombHitFrames() {
        let bombAnimatedAtlas = SKTextureAtlas(named: "boom")
        var exFrames: [SKTexture] = []
        let explosionTextureName = "explosion"
        exFrames.append(bombAnimatedAtlas.textureNamed(explosionTextureName))
        
        bombHitFrames = exFrames
    }
    
    func bombHit(sprite: SKNode, points: Int) {
        sprite.removeAllActions()
        sprite.physicsBody = nil
        let bombSound = SKAction.playSoundFileNamed("bomb.mp3", waitForCompletion: false)
        let explode = SKAction.animate(with: bombHitFrames,
                                       timePerFrame: 0.2,
                                       resize: false,
                                       restore: true)
        let seq = SKAction.sequence([bombSound, explode, SKAction.removeFromParent()])
        sprite.run(seq, withKey: "bombHit")
        
        showPoints(sprite: sprite, points: points)
    }
    
    func createArrow() {
        let arrow = SKSpriteNode(imageNamed: "myArrow")
        arrow.zPosition = 4
        arrow.physicsBody = SKPhysicsBody(rectangleOf: arrow.size)
        arrow.physicsBody?.affectedByGravity = false
        arrow.physicsBody?.categoryBitMask = arrowCategory
        arrow.physicsBody?.contactTestBitMask = baloonCategory | bombCategory
        arrow.physicsBody?.collisionBitMask = 0
        addChild(arrow)
        spawnArrow(sprite: arrow)
    }
    
    func createCloud() {
        let selector = rng(max: 2, min: 0)
        if selector == 1 {
            cloud = SKSpriteNode(imageNamed: "cloudA")
        }
        if selector == 2 {
            cloud = SKSpriteNode(imageNamed: "cloudB")
        }
        cloud?.zPosition = 1
        cloud?.physicsBody = SKPhysicsBody(rectangleOf: (cloud?.size)!)
        cloud?.physicsBody?.affectedByGravity = false
        cloud?.physicsBody?.categoryBitMask = cloudCategory
        cloud?.physicsBody?.contactTestBitMask = cloudCategory
        cloud?.physicsBody?.collisionBitMask = 0
        addChild(cloud!)
        spawnCloud(sprite: cloud!)
    }
    
    
    // MARK:- Sprites animation
    
    
    func spawnBaloon(sprite: SKSpriteNode) {
        
        //bounds for spawn
        let maxX = size.width / 2 - sprite.size.width / 2
        let minX = -size.width / 2 + sprite.size.width
        
        //spawn position
        let range = maxX - minX
        let posX = maxX - CGFloat(arc4random_uniform(UInt32(range)))
        sprite.position = CGPoint(x: posX, y: size.height / 2 + sprite.size.height)
        
        //movement
        let moveLeft = SKAction.moveBy(x: -size.width/20 , y: -size.height/2.5, duration: 4)
        let moveRight = SKAction.moveBy(x: size.width/20 , y: -size.height/2.5, duration: 4)
        let selector = arc4random_uniform(4)
        let number = 4 - selector
        if number == 1 {
            sprite.run(SKAction.sequence([moveLeft, moveRight, SKAction.removeFromParent()]))
        }
        if number == 2 {
            sprite.run(SKAction.sequence([moveRight, moveLeft, SKAction.removeFromParent()]))
        }
        if number == 3 {
            sprite.run(SKAction.sequence([moveRight, moveRight, SKAction.removeFromParent()]))
        }
        if number == 4 {
            sprite.run(SKAction.sequence([moveLeft, moveLeft, SKAction.removeFromParent()]))
        }
        
    }
    
    func spawnBomb(sprite: SKSpriteNode) {
        
        //bounds for spawn
        let maxX = size.width / 2 - sprite.size.width / 2
        let minX = -size.width / 2 + sprite.size.width
        
        //spawn position
        let range = maxX - minX
        let posX = maxX - CGFloat(arc4random_uniform(UInt32(range)))
        sprite.position = CGPoint(x: posX, y: size.height / 2 + sprite.size.height)
        
        //movement
        let drop = SKAction.moveBy(x: 0, y: -size.height - 2 * sprite.size.height, duration: 3)
        sprite.run(SKAction.sequence([drop, SKAction.removeFromParent()]))
        
    }
    
    func spawnArrow(sprite: SKSpriteNode) {
        
        sprite.position = CGPoint(x: (player?.position.x)!, y: (player?.position.y)! - (player?.position.y)! / 2)
        
        let fire = SKAction.moveBy(x: 0, y: size.height, duration: 0.5)
        sprite.run(SKAction.sequence([fire, SKAction.removeFromParent()]))
        
    }
    
    func spawnCloud(sprite: SKSpriteNode) {
        
        //bounds for spawn
        let maxY = size.height / 2 - sprite.size.height / 2
        let minY = -size.height / 2 + 6 * sprite.size.height
        
        //spawn position
        let range = maxY - minY
        let posY = maxY - CGFloat(arc4random_uniform(UInt32(range)))
        sprite.position = CGPoint(x: size.width / 2 + sprite.size.width, y: posY)
        
        //movement
        let moveLeft = SKAction.moveBy(x: -size.width - 2 * sprite.size.width, y: 0, duration: 15)
        sprite.run(SKAction.sequence([moveLeft, SKAction.removeFromParent()]))
        
    }

   
    // MARK:- Timers
  
    
    func startTimers(baloonTimeInterval: Double, bombTimeInterval: Double) {
        baloonTimer = Timer.scheduledTimer(withTimeInterval: baloonTimeInterval, repeats: true, block: {
            timer in
            self.createBaloon()
        })
        bombTimer = Timer.scheduledTimer(withTimeInterval: bombTimeInterval, repeats: true, block: {
            timer in
            self.createBomb()
        })
        
        
    }
    
    
    //Player movement
    func movePlayer(moveBy: CGFloat, forTheKey: String) {
        let moveAction = SKAction.moveBy(x: moveBy, y: 0, duration: 1)
        let repeatForEver = SKAction.repeatForever(moveAction)
        let seq = SKAction.sequence([moveAction, repeatForEver])
        player?.run(seq, withKey: forTheKey)
        animateFox()
       
        if forTheKey == "buttonRight" {
            player?.xScale = abs((player?.xScale)!) * -1.0
        }
        if forTheKey == "buttonLeft" {
            player?.xScale = abs((player?.xScale)!) * 1.0
        }
        
    }
    func buildFox() {
        let foxAnimatedAtlas = SKTextureAtlas(named: "fox")
        var walkFrames: [SKTexture] = []
        
        let numImages = foxAnimatedAtlas.textureNames.count
        for i in 0...numImages - 1 {
            let foxTextureName = "fox\(i)"
            walkFrames.append(foxAnimatedAtlas.textureNamed(foxTextureName))
        }
        foxWalkingFrames = walkFrames
        let firstFrameTexture = foxWalkingFrames[0]
        player = childNode(withName: "player") as? SKSpriteNode
        player?.texture = firstFrameTexture
        player?.size = firstFrameTexture.size()
        
        player?.zPosition = 4
        player?.physicsBody?.usesPreciseCollisionDetection = true
        player?.physicsBody?.categoryBitMask = playerCategory
        player?.physicsBody?.contactTestBitMask = bombCategory
        player?.physicsBody?.collisionBitMask = boundsCategory
        ground = childNode(withName: "ground") as? SKSpriteNode
        ground?.physicsBody?.categoryBitMask = boundsCategory
        ground?.physicsBody?.collisionBitMask = playerCategory
        leftWall = childNode(withName: "leftWall") as? SKSpriteNode
        leftWall?.physicsBody?.categoryBitMask = boundsCategory
        leftWall?.physicsBody?.collisionBitMask = playerCategory
        rightWall = childNode(withName: "rightWall") as? SKSpriteNode
        rightWall?.physicsBody?.categoryBitMask = boundsCategory
        rightWall?.physicsBody?.collisionBitMask = playerCategory
    }
    
    
    func animateFox() {
        player?.run(SKAction.repeatForever(
            SKAction.animate(with: foxWalkingFrames,
                             timePerFrame: 0.1,
                             resize: false,
                             restore: true)),
                    withKey:"walkingFox")
        if player?.texture == nil {
            let atlas = SKTextureAtlas(named: "fox")
            let texture = atlas.textureNamed("fox0")
            player?.texture = texture
        }
    }
    
    

    func gameOver(score: Int) {
        scene?.isPaused = true
        bombTimer?.invalidate()
        baloonTimer?.invalidate()
        cloudTimer?.invalidate()
        yourScoreLabel = SKLabelNode(text: "Your Score")
        yourScoreLabel?.position = CGPoint(x: 0, y: 200)
        yourScoreLabel?.zPosition = 11
        yourScoreLabel?.fontName = "Lucida Grande"
        yourScoreLabel?.fontSize = 64
        yourScoreLabel?.numberOfLines = 0
        if yourScoreLabel != nil {
            addChild(yourScoreLabel!)
        }
        
        pointsLabel = SKLabelNode(text: "\(score)")
        pointsLabel?.position = CGPoint(x: 0, y: 0)
        pointsLabel?.zPosition = 11
        pointsLabel?.fontName = "Lucida Grande"
        pointsLabel?.fontSize = 150
        pointsLabel?.numberOfLines = 0
        if pointsLabel != nil {
            addChild(pointsLabel!)
        }
        
        replayButton = SKSpriteNode(imageNamed: "playbutton")
        replayButton?.position = CGPoint(x: 0, y: -150)
        replayButton?.zPosition = 11
        replayButton?.name = "replay"
        addChild(replayButton!)
    }
    
    func rng (max: Int, min: Int) -> Double {
        let max = max
        let min = min
        let range = max - min
        let number = Double(max) - Double(arc4random_uniform(UInt32(range)))
        return number
        
    }
    
    func levelUp(level : Int) {
    
        levelLabel = SKLabelNode(text: "Level " + "\(levelCounter)")
        levelLabel?.position = CGPoint(x: size.width, y: 0)
        levelLabel?.zPosition = 11
        levelLabel?.fontName = "Lucida Grande"
        levelLabel?.fontSize = 200
        if levelLabel != nil {
            addChild(levelLabel!)
        }
        spawnLabel(sprite: levelLabel!)
        baloonTimer?.invalidate()
        bombTimer?.invalidate()
        if levelCounter > 3 {
            bombTimeInterval -= 0.01
            baloonTimeInterval -= 0.02
        } else {
            bombTimeInterval -= 1
            baloonTimeInterval -= 0.2
        }
        startTimers(baloonTimeInterval: baloonTimeInterval, bombTimeInterval: bombTimeInterval)
        
    }
    
    func spawnLabel(sprite: SKLabelNode) {
        
        //movement
        let dash1 = SKAction.moveTo(x: 0, duration: 0.8)
        let stop = SKAction.moveBy(x: 0, y: 0, duration: 1)
        let dash2 = SKAction.moveTo(x: -size.width, duration: 0.8)
        sprite.run(SKAction.sequence([dash1, stop, dash2, SKAction.removeFromParent()]))
        
    }
    
    func showPoints (sprite: SKNode, points: Int) {
        if points > 0 {
            floatingPointsLabel = SKLabelNode(text: "+\(points)")
        } else {
            floatingPointsLabel = SKLabelNode(text: "\(points)")
        }
        floatingPointsLabel?.position = sprite.position
        floatingPointsLabel?.zPosition = 11
        floatingPointsLabel?.fontName = "Lucida Grande"
        floatingPointsLabel?.fontSize = 30
        addChild(floatingPointsLabel!)
        let goUp = SKAction.moveBy(x: 0, y: 30, duration: 1)
        floatingPointsLabel?.run(SKAction.sequence([goUp, SKAction.removeFromParent()]))
       
    }
    
}

