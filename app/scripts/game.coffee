class Spirit.Game

  constructor: ->
    @game = new Phaser.Game(Spirit.Helpers.size().width, Spirit.Helpers.size().height, Phaser.CANVAS, '', @states())

  states: ->
   { preload: @preload, create: @create, update: @update, render: @render }

  preload: ->
    @ui = new Spirit.UI(@game)
    @engine = new Spirit.Engine(@game, @ui)

    @state = 'start'

    @engine.loadAssets()
    @engine.initPhysics()

  create: ->
    @game.add.sprite(0, 0, 'background')
    @game.add.sprite(20, 20, 'coins')
    @game.add.sprite(@game.world.width - 80, 20, 'heart')
    @ui.addText('score', '0', 98, 22, 'left')
    @ui.addText('lives', '3', @game.world.width - 120, 22, 'left')

    @engine.groupsManager.add('coin', Spirit.Behaviours.Coin, false)
    @engine.groupsManager.add('cloud_inactive', Spirit.Behaviours.CloudInactive, false)
    @engine.groupsManager.add('cloud_active', Spirit.Behaviours.CloudActive, false)
    @engine.groupsManager.add('enemy_random', Spirit.Behaviours.EnemyRandom, true)
    @engine.groupsManager.add('enemy_sticky', Spirit.Behaviours.EnemySticky, true)
    @engine.groupsManager.add('enemy_flying', Spirit.Behaviours.EnemyFlying, true)

    @player = new Spirit.Player(@engine, @game)
    @engine.start(@player)

    @game.physics.box2d.enable(@player.sprite, false)

    @player.initPhysics()
    @player.initCollisions()

    @ui.setScale()

    @game.physics.box2d.setBoundsToWorld()
    @game.input.onDown.add((=> @engine.handleState()), @)

  update: ->
    @player.updateRotation()

    if @engine.state == 'playing'
      @engine.groupsManager.periodicGenerate('cloud_inactive', @game.world.randomX, @game.world.randomY)
      @engine.groupsManager.periodicGenerate('enemy_random', @game.world.randomX, @game.world.randomY)
      @engine.groupsManager.periodicGenerate('enemy_sticky', @game.world.randomX, @game.world.randomY)
      @engine.groupsManager.periodicGenerate('enemy_flying', @game.world.randomX, @game.world.randomY)

      @engine.groupsManager.checkPending('cloud_active')
      @engine.groupsManager.checkPending('coin')

      @engine.groupsManager.checkOutdated('cloud_active')
      @engine.groupsManager.checkOutdated('coin')

      @engine.groupsManager.get('enemy_sticky').items.forEach (item) =>
        item.behaviour.snapToPlayer(@player.sprite.body)

      @engine.groupsManager.get('enemy_flying').items.forEach (item) =>
        item.behaviour.fly(@game.world)

  render: ->
    @ui.updateText('score', @engine.progressManager.score.toString()) if @engine.state == 'playing'
    @ui.updateText('lives', @engine.progressManager.lives.toString()) if @engine.state == 'playing'
