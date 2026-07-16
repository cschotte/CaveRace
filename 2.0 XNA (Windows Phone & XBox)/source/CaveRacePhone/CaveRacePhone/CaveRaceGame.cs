using System;
using System.IO;
using System.IO.IsolatedStorage;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Audio;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;

#if WINDOWS_PHONE
using Microsoft.Phone.Shell;
using Microsoft.Phone.Tasks;
using Microsoft.Phone.Marketplace;
#endif

namespace CaveRace
{
    public class CaveRaceGame : Microsoft.Xna.Framework.Game
    {
        private const int pixels = 32;

        #region Enum
        enum GameStatus { Menu, Start, Resume, Playing, About };
        #endregion

#if WINDOWS_PHONE
        private void CheckLicense()
        {
            if (isLicenseChecked == true) return;

            isTrial = license.IsTrial();
            //isTrial = false;

            isLicenseChecked = true;
        }
#endif

        #region Fields
#if WINDOWS_PHONE
        LicenseInformation license = new LicenseInformation();
        MarketplaceDetailTask marketplace = new MarketplaceDetailTask();
        bool isLicenseChecked = false;
        bool isTrial = false;
#endif
        // AI
        Random random = new Random();

        // Graphics
        GraphicsDeviceManager graphics;
        SpriteBatch spriteBatch;
        int frame = 0;

        SpriteFont spriteFont;

        // Game Sprites
        Texture2D backgroundTexture;
        Texture2D enemyTexture;
        Texture2D stoneTexture;
        Texture2D playerTexture;
        Texture2D tresureTexture;
        Texture2D bombTexture;
        Texture2D gamepadTexture;

        Texture2D desertTexture;
        Texture2D forestTexture;
        Texture2D winterTexture;
        Texture2D lavaTexture;

        Texture2D statusBarTexture;
        Texture2D statusToolsTexture;

        Texture2D introScreenTexture;
        Texture2D textTexture;

        // Game
        Map map = new Map();
        Player player = new Player();
        List<Enemy> enemys = new List<Enemy>();
        List<Bomb> bombs = new List<Bomb>();
        string[] levelname = new string[] { "Intro",
                                            "Forest 1",
                                            "Forest 2",
                                            "Forest 3",
                                            "Forest 4",
                                            "Forest 5",
                                            "Desert 1",
                                            "Desert 2",
                                            "Desert 3",
                                            "Desert 4",
                                            "Desert 5",
                                            "Winter 1",
                                            "Winter 2",
                                            "Winter 3",
                                            "Winter 4",
                                            "Winter 5",
                                            "Lava 1",
                                            "Lava 2",
                                            "Lava 3",
                                            "Lava 4",
                                            "Lava 5",
                                            "Lava 6",
                                            "Lava 7",
                                            "Lava 8",
                                            "End"
                                            };
        GameStatus gameStatus = GameStatus.Menu;

        bool showGameOver = false;
        bool showStart = false;
        int fade = 255;

        // Input
        Keys moveAction = Keys.None;
        Keys fireAction = Keys.None;

        // Sound
        SoundEffect[] bombSound = new SoundEffect[4];
        SoundEffect itemSound;
        SoundEffect squishSound;
        #endregion

        #region Load / Save Game sate
        void SaveGameSate()
        {
           IsolatedStorageSettings.ApplicationSettings["player"] = player;
           IsolatedStorageSettings.ApplicationSettings["map"] = map;
           IsolatedStorageSettings.ApplicationSettings["frame"] = frame;
           IsolatedStorageSettings.ApplicationSettings["enemys"] = enemys;
           IsolatedStorageSettings.ApplicationSettings["bombs"] = bombs;
           IsolatedStorageSettings.ApplicationSettings["moveAction"] = moveAction;
           IsolatedStorageSettings.ApplicationSettings["fireAction"] = fireAction;
        }

        void LoadGameSate()
        {
            Player p;
            if(IsolatedStorageSettings.ApplicationSettings.TryGetValue("player", out p))
            {
                player = p;
            }

            Map m;
            if (IsolatedStorageSettings.ApplicationSettings.TryGetValue("map", out m))
            {
                map = m;
            }

            int f;
            if (IsolatedStorageSettings.ApplicationSettings.TryGetValue("frame", out f))
            {
                frame = f;
            }

            List<Enemy> e;
            if (IsolatedStorageSettings.ApplicationSettings.TryGetValue("enemys", out e))
            {
                enemys = e;
            }

            List<Bomb> b;
            if (IsolatedStorageSettings.ApplicationSettings.TryGetValue("bombs", out b))
            {
                bombs = b;
            }

            Keys ma;
            if (IsolatedStorageSettings.ApplicationSettings.TryGetValue("moveAction", out ma))
            {
                moveAction = ma;
            }

            Keys fa;
            if (IsolatedStorageSettings.ApplicationSettings.TryGetValue("fireAction", out fa))
            {
                fireAction = fa;
            }

#if WINDOWS_PHONE
            isLicenseChecked = false;
#endif
        }
        #endregion

        #region Initialization
        public CaveRaceGame()
        {
            graphics = new GraphicsDeviceManager(this);

#if WINDOWS
            IsMouseVisible = true;
#endif

#if XBOX || WINDOWS
            graphics.PreferredBackBufferWidth = 800;
            graphics.PreferredBackBufferHeight = 480;
#endif

#if WINDOWS_PHONE
            graphics.IsFullScreen = true;
#endif
            Content.RootDirectory = "Content";

            // Frame rate is 30 fps by default for Windows Phone.
            TargetElapsedTime = TimeSpan.FromTicks(333333);
#if WINDOWS_PHONE
            InitializePhoneServices();
#endif
        }

        protected override void OnExiting(object sender, EventArgs args)
        {
            base.OnExiting(sender, args);
        }

#if WINDOWS_PHONE
        private void InitializePhoneServices()
        {
            PhoneApplicationService.Current.Activated += new EventHandler<ActivatedEventArgs>(Current_Activated);
            PhoneApplicationService.Current.Deactivated += new EventHandler<DeactivatedEventArgs>(Current_Deactivated);
            PhoneApplicationService.Current.Closing += new EventHandler<ClosingEventArgs>(Current_Closing);
            PhoneApplicationService.Current.Launching += new EventHandler<LaunchingEventArgs>(Current_Launching);
        }

        void Current_Launching(object sender, LaunchingEventArgs e)
        {
            LoadGameSate();
        }

        void Current_Closing(object sender, ClosingEventArgs e)
        {
            SaveGameSate();
        }

        void Current_Deactivated(object sender, DeactivatedEventArgs e)
        {
            SaveGameSate();
        }

        void Current_Activated(object sender, ActivatedEventArgs e)
        {
            LoadGameSate();
        }
#endif
        protected override void Initialize()
        {
#if WINDOWS
            AssemblyName name = this.GetType().Assembly.GetName();
            this.Window.Title = string.Format("{0} ({1})", Properties.Resources.ApplicationName, name.Version);
#endif

            base.Initialize();
        }
        #endregion

        #region Load Content
        protected override void LoadContent()
        {
            spriteBatch = new SpriteBatch(GraphicsDevice);

            // Sprites
            enemyTexture = Content.Load<Texture2D>("Sprites/Enemy");
            stoneTexture = Content.Load<Texture2D>("Sprites/Stone");
            playerTexture = Content.Load<Texture2D>("Sprites/Player");
            tresureTexture = Content.Load<Texture2D>("Sprites/Treasure");
            bombTexture = Content.Load<Texture2D>("Sprites/Bomb");

            gamepadTexture = Content.Load<Texture2D>("Sprites/Gamepad");

            desertTexture = Content.Load<Texture2D>("Sprites/Desert");
            forestTexture = Content.Load<Texture2D>("Sprites/Forest");
            winterTexture = Content.Load<Texture2D>("Sprites/Winter");
            lavaTexture = Content.Load<Texture2D>("Sprites/Lava");

            statusBarTexture = Content.Load<Texture2D>("Interface/statusBar");
            statusToolsTexture = Content.Load<Texture2D>("Interface/statusTools");

            introScreenTexture = Content.Load<Texture2D>("Interface/IntroScreen");
            textTexture = Content.Load<Texture2D>("Interface/Text");

            // Font
            spriteFont = Content.Load<SpriteFont>("Font");

            // Sounds
            bombSound[0] = Content.Load<SoundEffect>("Sounds/Bomb01");
            bombSound[1] = Content.Load<SoundEffect>("Sounds/Bomb02");
            bombSound[2] = Content.Load<SoundEffect>("Sounds/Bomb02");
            bombSound[3] = Content.Load<SoundEffect>("Sounds/Bomb03");

            itemSound = Content.Load<SoundEffect>("Sounds/Item");
            squishSound = Content.Load<SoundEffect>("Sounds/Squish");
        }
        #endregion

        #region Update
        protected override void Update(GameTime gameTime)
        {
            switch (gameStatus)
            {
                case GameStatus.Menu:
                    UpdateMenu();
#if WINDOWS_PHONE
                    CheckLicense();
#endif
                    break;

                case GameStatus.Playing:
                    UpdatePlaying();
                    break;

                default:
                    if (GamePad.GetState(PlayerIndex.One).Buttons.Back == ButtonState.Pressed) this.Exit();
                    break;
            }

            base.Update(gameTime);
        }

        void UpdateMenu()
        {
            #region GamePad
            GamePadState gp = GamePad.GetState(PlayerIndex.One);
            if (gp.Buttons.Back == ButtonState.Pressed) this.Exit();
            if (gp.Buttons.A == ButtonState.Pressed || gp.Buttons.Start == ButtonState.Pressed) gameStatus = GameStatus.Start;
            if (gp.Buttons.X == ButtonState.Pressed) gameStatus = GameStatus.Resume;
            #endregion

            #region Mouse
            MouseState ms = Mouse.GetState();
            if (ms.LeftButton == ButtonState.Pressed)
            {
                if (box(ms.X, ms.Y, 35, 106, 211, 155)) gameStatus = GameStatus.Start;
                if (box(ms.X, ms.Y, 45, 170, 243, 219)) gameStatus = GameStatus.Resume;
#if WINDOWS_PHONE
                if (isTrial)
                {
                    if (box(ms.X, ms.Y, 120, 400, 120+256, 400+64)) marketplace.Show();
                }
#endif
            }
            #endregion
        }

        void UpdatePlaying()
        {
            if (frame == 0)
            {
                moveAction = Keys.None;
                fireAction = Keys.None;
            }

            #region GamePad
            GamePadState gp = GamePad.GetState(PlayerIndex.One);
            if (gp.Buttons.Back == ButtonState.Pressed || gp.Buttons.B == ButtonState.Pressed)
            {
                SaveGameSate();
                gameStatus = GameStatus.Menu;
            }

            if (gp.DPad.Down == ButtonState.Pressed) moveAction = Keys.Down;
            if (gp.DPad.Up == ButtonState.Pressed) moveAction = Keys.Up;
            if (gp.DPad.Left == ButtonState.Pressed) moveAction = Keys.Left;
            if (gp.DPad.Right == ButtonState.Pressed) moveAction = Keys.Right;
            if (gp.Buttons.A == ButtonState.Pressed) fireAction = Keys.Space;
            #endregion

            #region Mouse
            MouseState ms = Mouse.GetState();
            if (ms.LeftButton == ButtonState.Pressed)
            {
#if WINDOWS_PHONE
                if (isPointInsideTriangle(new Vector2(576, 256), new Vector2(688, 368), new Vector2(576, 480), new Vector2(ms.X, ms.Y))) moveAction = Keys.Left;
                if (isPointInsideTriangle(new Vector2(800, 256), new Vector2(688, 368), new Vector2(800, 480), new Vector2(ms.X, ms.Y))) moveAction = Keys.Right;
                if (isPointInsideTriangle(new Vector2(576, 256), new Vector2(688, 368), new Vector2(800, 256), new Vector2(ms.X, ms.Y))) moveAction = Keys.Up;
                if (isPointInsideTriangle(new Vector2(576, 480), new Vector2(688, 368), new Vector2(800, 480), new Vector2(ms.X, ms.Y))) moveAction = Keys.Down;

                if (box(ms.X, ms.Y, 16, (480 - 128) - 16, 16 + 128, ((480 - 128) - 16) + 128)) fireAction = Keys.Space;
#endif
            }
            #endregion

            #region TouchPanel
            //if (TouchPanel.IsGestureAvailable)
            //{
            //    GestureSample gesture = TouchPanel.ReadGesture();

            //    if (gesture.GestureType == GestureType.HorizontalDrag)
            //    {
            //        if (gesture.Delta.X < 0) moveAction = Keys.Left;
            //        if (gesture.Delta.X > 0) moveAction = Keys.Right;
            //    }

            //    if (gesture.GestureType == GestureType.VerticalDrag)
            //    {
            //        if (gesture.Delta.Y < 0) moveAction = Keys.Up;
            //        if (gesture.Delta.Y > 0) moveAction = Keys.Down;
            //    }

            //    if (gesture.GestureType == GestureType.DoubleTap)
            //    {
            //        fireAction = Keys.Space;
            //    }
            //}
            #endregion

            #region Keyboard
            KeyboardState ks = Keyboard.GetState();

            if (ks.IsKeyDown(Keys.Left))
            {
                moveAction = Keys.Left;
            }

            if (ks.IsKeyDown(Keys.Right))
            {
                moveAction = Keys.Right;
            }

            if (ks.IsKeyDown(Keys.Up))
            {
                moveAction = Keys.Up;
            }

            if (ks.IsKeyDown(Keys.Down))
            {
                moveAction = Keys.Down;
            }

            if (ks.IsKeyDown(Keys.Space))
            {
                fireAction = Keys.Space;
            }

            if (ks.IsKeyDown(Keys.Escape))
            {
                SaveGameSate();
                gameStatus = GameStatus.Menu;
            }
            #endregion
        }
        #endregion

        #region Draw
        protected override void Draw(GameTime gameTime)
        {
            switch (gameStatus)
            {
                case GameStatus.Menu:
                    DrawMenu();
                    break;

                case GameStatus.Start:
                    player = new Player();
                    GameStart(player.levelId);
                    break;

                case GameStatus.Resume:
                    GameResume();
                    break;

                case GameStatus.Playing:
                    DrawPlaying();
                    break;
            }

            base.Draw(gameTime);
        }

        void DrawMenu()
        {
            GraphicsDevice.Clear(Color.Black);

            spriteBatch.Begin();

            Blit(0, 0, introScreenTexture);

            DrawText();

#if WINDOWS_PHONE
            if (isTrial)
            {
                BlitText(3, 120,400);
            }
#endif

            spriteBatch.End();
        }

        void GameStart(int levelId)
        {
            GraphicsDevice.Clear(Color.Black);

            frame = 0;
            fade = 255;
            showStart = true;

            int points = player.points;
            int lives = player.lives;

            map.Load(levelname[levelId]);
            player = map.GetPlayer();
            enemys = map.GetEnemys();
            bombs.Clear();

            player.points = points;
            player.lives = lives;

            player.levelId = levelId;

            backgroundTexture = forestTexture;
            if (levelname[levelId].StartsWith("Desert")) backgroundTexture = desertTexture;
            if (levelname[levelId].StartsWith("Winter")) backgroundTexture = winterTexture;
            if (levelname[levelId].StartsWith("Forest")) backgroundTexture = forestTexture;
            if (levelname[levelId].StartsWith("Lava")) backgroundTexture = lavaTexture;

            moveAction = Keys.None;
            fireAction = Keys.None;

            gameStatus = GameStatus.Playing;
        }

        void GameResume()
        {
            GameStart(player.levelId);

            LoadGameSate();

            backgroundTexture = forestTexture;
            if (levelname[player.levelId].StartsWith("Desert")) backgroundTexture = desertTexture;
            if (levelname[player.levelId].StartsWith("Winter")) backgroundTexture = winterTexture;
            if (levelname[player.levelId].StartsWith("Forest")) backgroundTexture = forestTexture;
            if (levelname[player.levelId].StartsWith("Lava")) backgroundTexture = lavaTexture;
        }

        void DrawPlaying()
        {
            GraphicsDevice.Clear(Color.Black);

            spriteBatch.Begin();

            DrawMap(backgroundTexture, map.background, true);
            DrawMap(tresureTexture, map.treasure, false);
            DrawMap(stoneTexture, map.stone, false);

            DrawPlayer();
            DrawEnemys();
            DrawBombs();

            CheckBombHit();
            CheckEnemyHit();

            DrawStatusBar();

            DrawGamePad();

            DrawText();

            spriteBatch.End();

            if (++frame > 7)
            {
                frame = 0;

                CheckTreasure();
                CheckLevelComplete();

                MoveEnemys();
                MovePlayer();

                UpdateBombs();
            }
        }
        #endregion

        #region Draw Game
        void DrawStatusBar()
        {
            Blit(0, 416, statusBarTexture);

            for (int i = 0; i < player.lives; i++)
            {
                BlitSprite((i * 28) + 180, 415, statusToolsTexture, 0, pixels);
            }

            for (int i = 0; i < player.energy; i++)
            {
                BlitSprite((i * 14) + 170, 447, statusToolsTexture, 1, pixels);
            }

            for (int i = 0; i < player.power; i++)
            {
                BlitSprite((i * 16) + 524, 416, statusToolsTexture, 2, pixels);
            }

            for (int i = 0; i < player.bombs; i++)
            {
                BlitSprite((i * 27) + 520, 448, statusToolsTexture, 3, pixels);
            }

            spriteBatch.DrawString(spriteFont, player.points.ToString(), new Vector2(339, 417), Color.Black);
            spriteBatch.DrawString(spriteFont, player.points.ToString(), new Vector2(340, 418), Color.White);

            spriteBatch.DrawString(spriteFont, levelname[player.levelId], new Vector2(339, 455), Color.Black);
            spriteBatch.DrawString(spriteFont, levelname[player.levelId], new Vector2(340, 456), Color.White);
        }

        void DrawGamePad()
        {
#if WINDOWS_PHONE
            // move pad
            float scale = 1.5f;
            BlitSprite((800 - 192) - 16, (480 - 192) - 16, gamepadTexture, 0, 128, scale);

            // fire pad
            BlitSprite(16, (480 - 128) - 16, gamepadTexture, 1, 128);
#endif
        }

        void DrawMap(Texture2D texture, byte[,] items, bool first)
        {
            for (int y = 0; y < Map.height; y++)
                for (int x = 0; x < Map.width; x++)
                {
                    if (items[x, y] != 0 || first)
                        BlitSprite(x * pixels, y * pixels, texture, items[x, y], pixels);
                }
        }

        void DrawEnemys()
        {
            foreach (Enemy enemy in enemys)
            {
                enemy.x += enemy.xmov;
                enemy.y += enemy.ymov;
                BlitSprite(enemy.x, enemy.y, enemyTexture, enemy.i, pixels);
            }
        }

        void DrawBombs()
        {
            foreach (Bomb bomb in bombs)
            {
                if (bomb.time > 1)
                {
                    BlitSprite(bomb.x, bomb.y, bombTexture, 1, pixels);
                }
                else
                {
                    if (frame < 2)
                    {
                        BlitSprite(bomb.x, bomb.y, bombTexture, 2, pixels); // klein
                        for (int p = 1; p <= bomb.power; p++)
                        {
                            BlitSprite(bomb.x - (p * pixels), bomb.y, bombTexture, 4, pixels); // left
                            BlitSprite(bomb.x + (p * pixels), bomb.y, bombTexture, 4, pixels); // right
                            BlitSprite(bomb.x, bomb.y - (p * pixels), bombTexture, 3, pixels); // up
                            BlitSprite(bomb.x, bomb.y + (p * pixels), bombTexture, 3, pixels); // down
                        }
                    }
                    else if (frame < 5)
                    {
                        BlitSprite(bomb.x, bomb.y, bombTexture, 5, pixels); // midde
                        for (int p = 1; p <= bomb.power; p++)
                        {
                            BlitSprite(bomb.x - (p * pixels), bomb.y, bombTexture, 7, pixels); // left
                            BlitSprite(bomb.x + (p * pixels), bomb.y, bombTexture, 7, pixels); // right
                            BlitSprite(bomb.x, bomb.y - (p * pixels), bombTexture, 6, pixels); // up
                            BlitSprite(bomb.x, bomb.y + (p * pixels), bombTexture, 6, pixels); // down
                        }
                    }
                    else if (frame < 8)
                    {
                        BlitSprite(bomb.x, bomb.y, bombTexture, 8, pixels); // groot
                        for (int p = 1; p <= bomb.power; p++)
                        {
                            BlitSprite(bomb.x - (p * pixels), bomb.y, bombTexture, 10, pixels); // left
                            BlitSprite(bomb.x + (p * pixels), bomb.y, bombTexture, 10, pixels); // right
                            BlitSprite(bomb.x, bomb.y - (p * pixels), bombTexture, 9, pixels); // up
                            BlitSprite(bomb.x, bomb.y + (p * pixels), bombTexture, 9, pixels); // down
                        }
                    }
                    else if (frame < 12)
                    {
                        BlitSprite(bomb.x, bomb.y, bombTexture, 5, pixels); // midde
                        for (int p = 1; p <= bomb.power; p++)
                        {
                            BlitSprite(bomb.x - (p * pixels), bomb.y, bombTexture, 7, pixels); // left
                            BlitSprite(bomb.x + (p * pixels), bomb.y, bombTexture, 7, pixels); // right
                            BlitSprite(bomb.x, bomb.y - (p * pixels), bombTexture, 6, pixels); // up
                            BlitSprite(bomb.x, bomb.y + (p * pixels), bombTexture, 6, pixels); // down
                        }
                    }
                    else
                    {
                        BlitSprite(bomb.x, bomb.y, bombTexture, 2, pixels); // midde
                        for (int p = 1; p <= bomb.power; p++)
                        {
                            BlitSprite(bomb.x - (p * pixels), bomb.y, bombTexture, 4, pixels); // left
                            BlitSprite(bomb.x + (p * pixels), bomb.y, bombTexture, 4, pixels); // right
                            BlitSprite(bomb.x, bomb.y - (p * pixels), bombTexture, 3, pixels); // up
                            BlitSprite(bomb.x, bomb.y + (p * pixels), bombTexture, 3, pixels); // down
                        }
                    }
                }
            }
        }

        void DrawPlayer()
        {
            if (player.energy < 1)
            {
                player.id = 5;
            }
            else
            {
                player.x += player.xmov;
                player.y += player.ymov;
            }
            BlitSprite(player.x, player.y, playerTexture, player.id, pixels);
        }

        void DrawText()
        {
            if (showStart)
            {
                BlitText(0);

                fade -= 2;

                if (fade <= 0)
                {
                    fade = 255;
                    showStart = false;
                }
            }

            if (showGameOver)
            {
                BlitText(2);

                fade -= 3;

                if (fade <= 0)
                {
                    fade = 255;
                    showGameOver = false;

                    gameStatus = GameStatus.Menu;
                }
            }
        }
        #endregion

        #region Game logic
        void MovePlayer()
        {
            if (player.energy <= 0) return;
            if (enemys.Count <= 0) return;

            player.id = 1;
            player.xmov = 0;
            player.ymov = 0;

            switch (moveAction)
            {
                case Keys.Down:
                    if ((player.y / pixels < Map.height -1) &&
                    (map.background[(player.x / pixels), (player.y / pixels) + 1] < 25) &&
                    (map.stone[(player.x / pixels), (player.y / pixels) + 1] < 5) &&
                    (map.bomb[(player.x / pixels), (player.y / pixels) + 1] == 0))
                    {
                        player.id = 1;
                        player.ymov = 4;
                    }
                    break;

                case Keys.Up:
                    if ((player.y / pixels > 0) &&
                    (map.background[(player.x / pixels), (player.y / pixels) - 1] < 25) &&
                    (map.stone[(player.x / pixels), (player.y / pixels) - 1] < 5) &&
                    (map.bomb[(player.x / pixels), (player.y / pixels) - 1] == 0))
                    {
                        player.id = 2;
                        player.ymov = -4;
                    }
                    break;

                case Keys.Left:
                    if ((player.x / pixels > 0) &&
                    (map.background[(player.x / pixels) - 1, (player.y / pixels)] < 25) &&
                    (map.stone[(player.x / pixels) - 1, (player.y / pixels)] < 5) &&
                    (map.bomb[(player.x / pixels) - 1, (player.y / pixels)] == 0))
                    {
                        player.id = 3;
                        player.xmov = -4;
                    }
                    break;

                case Keys.Right:
                    if ((player.x / pixels < Map.width -1) &&
                    (map.background[(player.x / pixels) + 1, (player.y / pixels)] < 25) &&
                    (map.stone[(player.x / pixels) + 1, (player.y / pixels)] < 5) &&
                    (map.bomb[(player.x / pixels) + 1, (player.y / pixels)] == 0))
                    {
                        player.id = 4;
                        player.xmov = 4;
                    }
                    break;
            }

            switch (fireAction)
            {
                case Keys.Space:
                    if (player.bombs > 0 && (map.bomb[player.x / pixels, player.y / pixels] < 1))
                    {
                        Bomb myBomb = new Bomb();
                        myBomb.x = player.x;
                        myBomb.y = player.y;
                        myBomb.power = player.power;

                        bombs.Add(myBomb);

                        map.bomb[player.x / pixels, player.y / pixels] = 1;

                        player.bombs--;

                        if (player.points >= 5) player.points -= 5;

                        //tickingSound.Play();
                    }
                    break;
            }
        }

        void MoveEnemys()
        {
            foreach (Enemy enemy in enemys)
            {
                int d = random.Next() % 4;

                enemy.xmov = 0;
                enemy.ymov = 0;

                switch (d)
                {
                    case 0: // down
                        if ((enemy.y / pixels < Map.height -1) &&
                            (map.background[(enemy.x / pixels), (enemy.y / pixels) + 1] < 25) &&
                            (map.stone[(enemy.x / pixels), (enemy.y / pixels) + 1] < 5) &&
                            (map.bomb[(enemy.x / pixels), (enemy.y / pixels) + 1] == 0))
                        {
                            enemy.ymov = 4;
                        }
                        break;

                    case 1: // up
                        if ((enemy.y / pixels > 0) &&
                            (map.background[(enemy.x / pixels), (enemy.y / pixels) - 1] < 25) &&
                            (map.stone[(enemy.x / pixels), (enemy.y / pixels) - 1] < 5) &&
                            (map.bomb[(enemy.x / pixels), (enemy.y / pixels) - 1] == 0))
                        {
                            enemy.ymov = -4;
                        }
                        break;

                    case 3: // left
                        if ((enemy.x / pixels > 0) &&
                            (map.background[(enemy.x / pixels) - 1, (enemy.y / pixels)] < 25) &&
                            (map.stone[(enemy.x / pixels) - 1, (enemy.y / pixels)] < 5) &&
                            (map.bomb[(enemy.x / pixels) - 1, (enemy.y / pixels)] == 0))
                        {
                            enemy.xmov = -4;
                        }
                        break;

                    case 2: // right
                        if ((enemy.x / pixels < Map.width -1) &&
                            (map.background[(enemy.x / pixels) + 1, (enemy.y / pixels)] < 25) &&
                            (map.stone[(enemy.x / pixels) + 1, (enemy.y / pixels)] < 5) &&
                            (map.bomb[(enemy.x / pixels) + 1, (enemy.y / pixels)] == 0))
                        {
                            enemy.xmov = 4;
                        }
                        break;
                }
            }
        }

        void UpdateBombs()
        {
            for (int i = 0; i < bombs.Count; i++)
            {
                bombs[i].time -= 1;

                if (bombs[i].time == 1) bombSound[random.Next() % 4].Play();

                if (bombs[i].time <= 0)
                {
                    map.bomb[bombs[i].x / pixels, bombs[i].y / pixels] = 0;
                    bombs.RemoveAt(i);
                    player.bombs++;
                }
            }
        }

        void CheckEnemyHit()
        {
            foreach (Enemy enemy in enemys)
            {
                if (enemy.x == player.x && enemy.y == player.y)
                {
                    player.energy -= 2;

                    if (player.energy < 0)
                    {
                        player.energy = 0;
                    }
                }
            }
        }

        void CheckBombHit()
        {
            foreach (Bomb bomb in bombs)
            {
                if (bomb.time == 1)
                {
                    for (int p = 1; p <= bomb.power; p++)
                    {
                        int x = (bomb.x / pixels);
                        int y = (bomb.y / pixels);

                        int up = y - p;
                        int down = y + p;
                        int left = x - p;
                        int right = x + p;

                        if (right >= Map.width) right = Map.width - 1;
                        if (left < 0) left = 0;
                        if (up < 0) up = 0;
                        if (down >= Map.height) down = Map.height - 1;

                        #region stone
                        // Check stone
                        if (map.stone[x, y] < 9) map.stone[x, y] = 0;         // static
                        if (map.stone[right, y] < 9) map.stone[right, y] = 0; // right
                        if (map.stone[left, y] < 9) map.stone[left, y] = 0;   // left
                        if (map.stone[x, up] < 9) map.stone[x, up] = 0;       // up
                        if (map.stone[x, down] < 9) map.stone[x, down] = 0;   // down
                        #endregion

                        #region treasure
                        // Check treasure
                        if (map.treasure[x, y] > 0) map.treasure[x, y] = 0;         // static
                        if (map.treasure[right, y] > 0) map.treasure[right, y] = 0; // right
                        if (map.treasure[left, y] > 0) map.treasure[left, y] = 0;   // left
                        if (map.treasure[x, up] > 0) map.treasure[x, up] = 0;       // up
                        if (map.treasure[x, down] > 0) map.treasure[x, down] = 0;   // down
                        #endregion

                        #region bomb
                        // Check bombs
                        if (map.bomb[right, y] > 0)
                        {
                            for (int i = 0; i < bombs.Count; i++)
                            {
                                if ((bombs[i].x / pixels) == right && (bombs[i].y / pixels) == y) bombs[i].time = 1;
                            }
                        }
                        if (map.bomb[left, y] > 0)
                        {
                            for (int i = 0; i < bombs.Count; i++)
                            {
                                if ((bombs[i].x / pixels) == left && (bombs[i].y / pixels) == y) bombs[i].time = 1;
                            }
                        }
                        if (map.bomb[x, up] > 0)
                        {
                            for (int i = 0; i < bombs.Count; i++)
                            {
                                if ((bombs[i].x / pixels) == x && (bombs[i].y / pixels) == up) bombs[i].time = 1;
                            }
                        }
                        if (map.bomb[x, down] > 0)
                        {
                            for (int i = 0; i < bombs.Count; i++)
                            {
                                if ((bombs[i].x / pixels) == x && (bombs[i].y / pixels) == down) bombs[i].time = 1;
                            }
                        }
                        #endregion

                        #region enemy
                        // Check enemy
                        List<int> killenemys = new List<int>();
                        for (int i = 0; i < enemys.Count; i++)
                        {
                            // right
                            if (box(enemys[i].x, enemys[i].y, (right * pixels) - 16, bomb.y - 16, (right * pixels) + 16, bomb.y + 16))
                            {
                                squishSound.Play();

                                killenemys.Add(i);
                                player.points += 75;
                            }

                            // left
                            if (box(enemys[i].x, enemys[i].y, (left * pixels) - 16, bomb.y - 16, (left * pixels) + 16, bomb.y + 16))
                            {
                                squishSound.Play();

                                killenemys.Add(i);
                                player.points += 75;
                            }

                            // up
                            if (box(enemys[i].x, enemys[i].y, bomb.x - 16, (up * pixels) - 16, bomb.x + 16, (up * pixels) + 16))
                            {
                                squishSound.Play();

                                killenemys.Add(i);
                                player.points += 75;
                            }

                            // down
                            if (box(enemys[i].x, enemys[i].y, bomb.x - 16, (down * pixels) - 16, bomb.x + 16, (down * pixels) + 16))
                            {
                                squishSound.Play();

                                killenemys.Add(i);
                                player.points += 75;
                            }
                        }

                        foreach (int i in killenemys)
                        {
                            try
                            {
                                enemys.RemoveAt(i);
                            }
                            catch (Exception)
                            {
                            }
                        }
                        #endregion

                        #region player
                        // right
                        if (box(player.x, player.y, (right * pixels) - 16, bomb.y - 16, (right * pixels) + 16, bomb.y + 16))
                        {
                            player.energy = 0;
                        }

                        // left
                        if (box(player.x, player.y, (left * pixels) - 16, bomb.y - 16, (left * pixels) + 16, bomb.y + 16))
                        {
                            player.energy = 0;
                        }

                        // up
                        if (box(player.x, player.y, bomb.x - 16, (up * pixels) - 16, bomb.x + 16, (up * pixels) + 16))
                        {
                            player.energy = 0;
                        }

                        // down
                        if (box(player.x, player.y, bomb.x - 16, (down * pixels) - 16, bomb.x + 16, (down * pixels) + 16))
                        {
                            player.energy = 0;
                        }

                        // normal
                        if (box(player.x, player.y, bomb.x - 16, bomb.y - 16, bomb.x + 16, bomb.y + 16))
                        {
                            player.energy = 0;
                        }
                        #endregion
                    }
                }
            }
        }

        void CheckLevelComplete()
        {
            // next level
            if (enemys.Count <= 0)
            {
                player.levelId++;

#if WINDOWS_PHONE
                if (isTrial)
                {
                    if (player.levelId > 4)
                    {
                        player.levelId = 4;

                        showGameOver = true;

                        return;
                    }
                }
#endif

                if (player.levelId > levelname.GetLength(0) - 1) //.Count()
                {
                    player.levelId = 0;

                    showGameOver = true;

                    return;
                }

                player.points += 100;

                GameStart(player.levelId);
            }
            
            if (player.energy <= 0) 
            {
                // restart level
                fade -= 50;

                if (fade <= 0)
                {
                    fade = 255;

                    // player killed, try again
                    player.points -= 50;
                    player.lives -= 1;

                    if (player.points < 0) player.points = 0;

                    GameStart(player.levelId);
                }
            }
            
            if (player.lives <= 0)
            {
                // player killed, game over
                showGameOver = true;
                showStart = false;
                gameStatus = GameStatus.Menu;
            }
        }

        void CheckTreasure()
        {
            // treasure
            if (map.treasure[player.x / pixels, player.y / pixels] > 0)
            {
                itemSound.Play();

                map.treasure[player.x / pixels, player.y / pixels] = 0;

                player.points += 50;
            }

            // power
            if (map.stone[player.x / pixels, player.y / pixels] == 1)
            {
                itemSound.Play();

                map.stone[player.x / pixels, player.y / pixels] = 0;

                if (++player.power > 4) player.power = 4;

                player.points += 50;
            }

            // bomb
            if (map.stone[player.x / pixels, player.y / pixels] == 2)
            {
                itemSound.Play();

                map.stone[player.x / pixels, player.y / pixels] = 0;

                if (++player.bombs > 4) player.bombs = 4;

                player.points += 50;
            }

            // energy
            if (map.stone[player.x / pixels, player.y / pixels] == 3)
            {
                itemSound.Play();

                map.stone[player.x / pixels, player.y / pixels] = 0;

                player.energy = 9;

                player.points += 50;
            }

            // lives
            if (map.stone[player.x / pixels, player.y / pixels] == 4)
            {
                itemSound.Play();

                map.stone[player.x / pixels, player.y / pixels] = 0;

                if (++player.lives > 4) player.lives = 4;

                player.points += 50;
            }

        }
        #endregion

        #region Helpers
        void Blit(int x, int y, Texture2D texture)
        {
            spriteBatch.Draw(texture, new Vector2(x, y), Color.White);
        }

        void BlitSprite(int x, int y, Texture2D texture, int index, int pixels)
        {
            int width = texture.Width / pixels;
            int xpos = (index % width) * pixels;
            int ypos = index > 0 ? (index / width) * pixels : 0;

            spriteBatch.Draw(texture, new Vector2(x, y), new Rectangle(xpos, ypos, pixels, pixels), Color.White, 0, new Vector2(0,0), 1, SpriteEffects.None, 0);
        }

        void BlitSprite(int x, int y, Texture2D texture, int index, int pixels, float scale)
        {
            int width = texture.Width / pixels;
            int xpos = (index % width) * pixels;
            int ypos = index > 0 ? (index / width) * pixels : 0;

            spriteBatch.Draw(texture, new Vector2(x, y), new Rectangle(xpos, ypos, pixels, pixels), Color.White, 0, new Vector2(0,0), scale, SpriteEffects.None, 0);
        }

        void BlitText(int index)
        {
            spriteBatch.Draw(textTexture, new Vector2(272, 176), new Rectangle(0, index * 64, 265, 64), new Color(fade, fade, fade, fade));
        }

        void BlitText(int index, int x, int y)
        {
            spriteBatch.Draw(textTexture, new Vector2(x, y), new Rectangle(0, index * 64, 265, 64), Color.White);
        }

        bool box(int x, int y, int x1, int y1, int x2, int y2)
        {
            if (x >= x1 && x <= x2 && y >= y1 && y <= y2) return true;

            return false;
        }

        private static bool isPointInsideTriangle(Vector2 Triang0, Vector2 Triang1, Vector2 Triang2, Vector2 p)
        {
            // Translated to C# from: http://www.ddj.com/184404201
            Vector2 e0 = p - Triang0;
            Vector2 e1 = Triang1 - Triang0;
            Vector2 e2 = Triang2 - Triang0;

            float u, v = 0;
            if (e1.X == 0)
            {
                if (e2.X == 0) return false;
                u = e0.X / e2.X;
                if (u < 0 || u > 1) return false;
                if (e1.Y == 0) return false;
                v = (e0.Y - e2.Y * u) / e1.Y;
                if (v < 0) return false;
            }
            else
            {
                float d = e2.Y * e1.X - e2.X * e1.Y;
                if (d == 0) return false;
                u = (e0.Y * e1.X - e0.X * e1.Y) / d;
                if (u < 0 || u > 1) return false;
                v = (e0.X - e2.X * u) / e1.X;
                if (v < 0) return false;
                if ((u + v) > 1) return false;
            }

            return true;
        }  
        #endregion
    }
}