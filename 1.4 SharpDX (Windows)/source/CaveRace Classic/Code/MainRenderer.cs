using System;
using System.Collections.Generic;
using SharpDX;
using SharpDX.Direct2D1;
using CommonDX;
using Windows.UI.Xaml.Controls;
using SharpDX.Multimedia;
using SharpDX.XAudio2;
using SharpDX.IO;

namespace CaveRace_Classic
{
    class MainRenderer : Component
    {
        #region Fields

        const int pixels = 32;

        DeviceManager graphics;

        // my 'best' Artificial intelligence :-)
        Random random = new Random();

        int frame = 0; // Old style

        Bitmap backgroundTexture;
        Bitmap enemyTexture;
        Bitmap stoneTexture;
        Bitmap playerTexture;
        Bitmap tresureTexture;
        Bitmap bombTexture;
        Bitmap gamepadTexture;

        Bitmap desertTexture;
        Bitmap forestTexture;
        Bitmap winterTexture;
        Bitmap lavaTexture;

        Bitmap statusBarTexture;
        Bitmap statusToolsTexture;
        Bitmap textTexture;

        

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

        bool showGameOver = false;
        bool showStart = false;
        float fade = 1.0f;

        // Input
        public enum Keys { None, Up, Down, Left, Right, Bomb };
        public Keys moveAction = Keys.None;
        public Keys fireAction = Keys.None;

        // Sound
        SoundStream[] bombSound = new SoundStream[4];
        SoundStream itemSound;
        SoundStream squishSound;
        SoundStream tickingSound;

        XAudio2 xaudio;
        #endregion

        #region Initialization
        public MainRenderer(Windows.UI.Xaml.UIElement rootForPointerEvents, Windows.UI.Xaml.UIElement rootOfLayout)
        {
        }
   
        public virtual void Initialize(DeviceManager deviceManager)
        {
            graphics = deviceManager;

            // Sprites
            playerTexture = BitmapFromFile(@"Assets\Sprites\Player.png");
            tresureTexture = BitmapFromFile(@"Assets\Sprites\Treasure.png");
            stoneTexture = BitmapFromFile(@"Assets\Sprites\Stone.png");
            enemyTexture = BitmapFromFile(@"Assets\Sprites\Enemy.png");
            bombTexture = BitmapFromFile(@"Assets\Sprites\Bomb.png");

            gamepadTexture = BitmapFromFile(@"Assets\Sprites\Gamepad.png");

            desertTexture = BitmapFromFile(@"Assets\Sprites\Desert.png");
            forestTexture = BitmapFromFile(@"Assets\Sprites\Forest.png");
            winterTexture = BitmapFromFile(@"Assets\Sprites\Winter.png");
            lavaTexture = BitmapFromFile(@"Assets\Sprites\Lava.png");

            statusBarTexture = BitmapFromFile(@"Assets\Interface\statusBar.png");
            statusToolsTexture = BitmapFromFile(@"Assets\Interface\statusTools.png");

            textTexture = BitmapFromFile(@"Assets\Interface\Text.png");

            // Sounds
            xaudio = new XAudio2();
            var masteringsound = new MasteringVoice(xaudio);

            bombSound[0] = LoadSound("Bomb01.wav");
            bombSound[1] = LoadSound("Bomb02.wav");
            bombSound[2] = LoadSound("Bomb02.wav");
            bombSound[3] = LoadSound("Bomb04.wav");

            itemSound = LoadSound("item.wav");
            squishSound = LoadSound("Squish.wav");
            tickingSound = LoadSound("Ticking.wav");

            GameStart(0);
        }

        private SoundStream LoadSound(string file)
        {
            var nativefilestream = new NativeFileStream(
                            @"Assets\Sounds\" + file,
                            NativeFileMode.Open,
                            NativeFileAccess.Read,
                            NativeFileShare.Read);

            return new SoundStream(nativefilestream);
        }

        private void PlaySound(SoundStream soundstream)
        {
            //AudioBuffer buffer;

            //WaveFormat waveFormat = soundstream.Format;
            //buffer = new AudioBuffer();
            
            //DataStream ds = soundstream.ToDataStream();
            //buffer.AudioBytes = (int)ds.Length;
            //buffer.Stream = ds;
            //buffer.Flags = BufferFlags.EndOfStream;

            //SourceVoice sourceVoice = new SourceVoice(xaudio, waveFormat, true);
            //sourceVoice.SubmitSourceBuffer(buffer, soundstream.DecodedPacketsInfo);
            //sourceVoice.Start();   
        }

        async void GameStart(int levelId)
        {
            frame = 0;
            fade = 1.0f;
            showStart = true;

            int points = player.points;
            int lives = player.lives;

            await map.Load(levelname[levelId]);
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
        }
        #endregion

        #region Update
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
                        if ((enemy.y / pixels < map.Height - 1) &&
                            (map.background[(enemy.x / pixels), (enemy.y / pixels) + 1] < 25) &&
                            (map.stone[(enemy.x / pixels), (enemy.y / pixels) + 1] < 5) &&
                            (map.bomb[(enemy.x / pixels), (enemy.y / pixels) + 1] == 0))
                        {
                            enemy.ymov = 2;
                        }
                        break;

                    case 1: // up
                        if ((enemy.y / pixels > 0) &&
                            (map.background[(enemy.x / pixels), (enemy.y / pixels) - 1] < 25) &&
                            (map.stone[(enemy.x / pixels), (enemy.y / pixels) - 1] < 5) &&
                            (map.bomb[(enemy.x / pixels), (enemy.y / pixels) - 1] == 0))
                        {
                            enemy.ymov = -2;
                        }
                        break;

                    case 3: // left
                        if ((enemy.x / pixels > 0) &&
                            (map.background[(enemy.x / pixels) - 1, (enemy.y / pixels)] < 25) &&
                            (map.stone[(enemy.x / pixels) - 1, (enemy.y / pixels)] < 5) &&
                            (map.bomb[(enemy.x / pixels) - 1, (enemy.y / pixels)] == 0))
                        {
                            enemy.xmov = -2;
                        }
                        break;

                    case 2: // right
                        if ((enemy.x / pixels < map.Width - 1) &&
                            (map.background[(enemy.x / pixels) + 1, (enemy.y / pixels)] < 25) &&
                            (map.stone[(enemy.x / pixels) + 1, (enemy.y / pixels)] < 5) &&
                            (map.bomb[(enemy.x / pixels) + 1, (enemy.y / pixels)] == 0))
                        {
                            enemy.xmov = 2;
                        }
                        break;
                }
            }
        }

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
                    if ((player.y / pixels < map.Height - 1) &&
                    (map.background[(player.x / pixels), (player.y / pixels) + 1] < 25) &&
                    (map.stone[(player.x / pixels), (player.y / pixels) + 1] < 5) &&
                    (map.bomb[(player.x / pixels), (player.y / pixels) + 1] == 0))
                    {
                        player.id = 1;
                        player.ymov = 2;
                    }
                    break;

                case Keys.Up:
                    if ((player.y / pixels > 0) &&
                    (map.background[(player.x / pixels), (player.y / pixels) - 1] < 25) &&
                    (map.stone[(player.x / pixels), (player.y / pixels) - 1] < 5) &&
                    (map.bomb[(player.x / pixels), (player.y / pixels) - 1] == 0))
                    {
                        player.id = 2;
                        player.ymov = -2;
                    }
                    break;

                case Keys.Left:
                    if ((player.x / pixels > 0) &&
                    (map.background[(player.x / pixels) - 1, (player.y / pixels)] < 25) &&
                    (map.stone[(player.x / pixels) - 1, (player.y / pixels)] < 5) &&
                    (map.bomb[(player.x / pixels) - 1, (player.y / pixels)] == 0))
                    {
                        player.id = 3;
                        player.xmov = -2;
                    }
                    break;

                case Keys.Right:
                    if ((player.x / pixels < map.Width - 1) &&
                    (map.background[(player.x / pixels) + 1, (player.y / pixels)] < 25) &&
                    (map.stone[(player.x / pixels) + 1, (player.y / pixels)] < 5) &&
                    (map.bomb[(player.x / pixels) + 1, (player.y / pixels)] == 0))
                    {
                        player.id = 4;
                        player.xmov = 2;
                    }
                    break;
            }

            switch (fireAction)
            {
                case Keys.Bomb:
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

                        PlaySound(tickingSound);
                    }
                    break;
            }
        }

        void UpdateBombs()
        {
            for (int i = 0; i < bombs.Count; i++)
            {
                bombs[i].time -= 1;

                if (bombs[i].time == 1) PlaySound(bombSound[random.Next() % 4]);

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

                        if (right >= map.Width) right = map.Width - 1;
                        if (left < 0) left = 0;
                        if (up < 0) up = 0;
                        if (down >= map.Height) down = map.Height - 1;

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
                                PlaySound(squishSound);

                                killenemys.Add(i);
                                player.points += 75;
                            }

                            // left
                            if (box(enemys[i].x, enemys[i].y, (left * pixels) - 16, bomb.y - 16, (left * pixels) + 16, bomb.y + 16))
                            {
                                PlaySound(squishSound);

                                killenemys.Add(i);
                                player.points += 75;
                            }

                            // up
                            if (box(enemys[i].x, enemys[i].y, bomb.x - 16, (up * pixels) - 16, bomb.x + 16, (up * pixels) + 16))
                            {
                                PlaySound(squishSound);

                                killenemys.Add(i);
                                player.points += 75;
                            }

                            // down
                            if (box(enemys[i].x, enemys[i].y, bomb.x - 16, (down * pixels) - 16, bomb.x + 16, (down * pixels) + 16))
                            {
                                PlaySound(squishSound);

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

        void CheckTreasure()
        {
            // treasure
            if (map.treasure[player.x / pixels, player.y / pixels] > 0)
            {
                PlaySound(itemSound);

                map.treasure[player.x / pixels, player.y / pixels] = 0;

                player.points += 50;
            }

            // power
            if (map.stone[player.x / pixels, player.y / pixels] == 1)
            {
                PlaySound(itemSound);

                map.stone[player.x / pixels, player.y / pixels] = 0;

                if (++player.power > 4) player.power = 4;

                player.points += 50;
            }

            // bomb
            if (map.stone[player.x / pixels, player.y / pixels] == 2)
            {
                PlaySound(itemSound);

                map.stone[player.x / pixels, player.y / pixels] = 0;

                if (++player.bombs > 4) player.bombs = 4;

                player.points += 50;
            }

            // energy
            if (map.stone[player.x / pixels, player.y / pixels] == 3)
            {
                PlaySound(itemSound);

                map.stone[player.x / pixels, player.y / pixels] = 0;

                player.energy = 9;

                player.points += 50;
            }

            // lives
            if (map.stone[player.x / pixels, player.y / pixels] == 4)
            {
                PlaySound(itemSound);

                map.stone[player.x / pixels, player.y / pixels] = 0;

                if (++player.lives > 4) player.lives = 4;

                player.points += 50;
            }

        }

        void CheckLevelComplete()
        {
            // next level
            if (enemys.Count <= 0)
            {
                player.levelId++;

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
                fade -= 0.1f;

                if (fade <= 0)
                {
                    fade = 1.0f;

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
                //gameStatus = GameStatus.Menu;
            }
        }
        #endregion

        #region Draw
        public virtual void Render(TargetBase target)
        {
            var context2D = target.DeviceManager.ContextDirect2D;

            context2D.BeginDraw();

            DrawMap(backgroundTexture, map.background, true, context2D);
            DrawMap(tresureTexture, map.treasure, false, context2D);
            DrawMap(stoneTexture, map.stone, false, context2D);

            DrawPlayer(context2D);
            DrawEnemys(context2D);
            DrawBombs(context2D);

            CheckBombHit();
            CheckEnemyHit();

            DrawStatusBar(context2D);

            DrawText(context2D);

            context2D.EndDraw();

            if (++frame > 15) // Old style from ms-dos caverace game, use the gameTime in production code!
            {
                frame = 0;

                CheckTreasure();
                CheckLevelComplete();

                MoveEnemys();
                MovePlayer();

                UpdateBombs();
                
                moveAction = Keys.None;
                fireAction = Keys.None;
            }
        }

        void DrawMap(Bitmap texture, byte[,] items, bool first, DeviceContext context2D)
        {
            for (int y = 0; y < map.Height; y++)
                for (int x = 0; x < map.Width; x++)
                {
                    if (items[x, y] != 0 || first)
                        BlitSprite(x * pixels, y * pixels, texture, items[x, y], context2D);
                }
        }

        void DrawEnemys(DeviceContext context2D)
        {
            foreach (Enemy enemy in enemys)
            {
                enemy.x += enemy.xmov;
                enemy.y += enemy.ymov;
                BlitSprite(enemy.x, enemy.y, enemyTexture, enemy.i, context2D);
            }
        }

        void DrawPlayer(DeviceContext context2D)
        {
            player.x += player.xmov;
            player.y += player.ymov;
            BlitSprite(player.x, player.y, playerTexture, player.id, context2D);
        }

        void DrawStatusBar(DeviceContext context2D)
        {
            Blit(0, 416, statusBarTexture, context2D);

            for (int i = 0; i < player.lives; i++)
            {
                BlitSprite((i * 28) + 180, 415, statusToolsTexture, 0, context2D);
            }

            for (int i = 0; i < player.energy; i++)
            {
                BlitSprite((i * 14) + 170, 447, statusToolsTexture, 1, context2D);
            }

            for (int i = 0; i < player.power; i++)
            {
                BlitSprite((i * 16) + 524, 416, statusToolsTexture, 2, context2D);
            }

            for (int i = 0; i < player.bombs; i++)
            {
                BlitSprite((i * 27) + 520, 448, statusToolsTexture, 3, context2D);
            }

            //spriteBatch.DrawString(spriteFont, player.points.ToString(), new Vector2(339, 417), Color.Black);
            //spriteBatch.DrawString(spriteFont, player.points.ToString(), new Vector2(340, 418), Color.White);

            //spriteBatch.DrawString(spriteFont, levelname[player.levelId], new Vector2(339, 455), Color.Black);
            //spriteBatch.DrawString(spriteFont, levelname[player.levelId], new Vector2(340, 456), Color.White);
        }

        void DrawBombs(DeviceContext context2D)
        {
            foreach (Bomb bomb in bombs)
            {
                if (bomb.time > 1)
                {
                    BlitSprite(bomb.x, bomb.y, bombTexture, 1, context2D);
                }
                else
                {
                    if (frame < 4)
                    {
                        BlitSprite(bomb.x, bomb.y, bombTexture, 2, context2D); // klein
                        for (int p = 1; p <= bomb.power; p++)
                        {
                            BlitSprite(bomb.x - (p * pixels), bomb.y, bombTexture, 4, context2D); // left
                            BlitSprite(bomb.x + (p * pixels), bomb.y, bombTexture, 4, context2D); // right
                            BlitSprite(bomb.x, bomb.y - (p * pixels), bombTexture, 3, context2D); // up
                            BlitSprite(bomb.x, bomb.y + (p * pixels), bombTexture, 3, context2D); // down
                        }
                    }
                    else if (frame < 10)
                    {
                        BlitSprite(bomb.x, bomb.y, bombTexture, 5, context2D); // midde
                        for (int p = 1; p <= bomb.power; p++)
                        {
                            BlitSprite(bomb.x - (p * pixels), bomb.y, bombTexture, 7, context2D); // left
                            BlitSprite(bomb.x + (p * pixels), bomb.y, bombTexture, 7, context2D); // right
                            BlitSprite(bomb.x, bomb.y - (p * pixels), bombTexture, 6, context2D); // up
                            BlitSprite(bomb.x, bomb.y + (p * pixels), bombTexture, 6, context2D); // down
                        }
                    }
                    else if (frame < 16)
                    {
                        BlitSprite(bomb.x, bomb.y, bombTexture, 8, context2D); // groot
                        for (int p = 1; p <= bomb.power; p++)
                        {
                            BlitSprite(bomb.x - (p * pixels), bomb.y, bombTexture, 10, context2D); // left
                            BlitSprite(bomb.x + (p * pixels), bomb.y, bombTexture, 10, context2D); // right
                            BlitSprite(bomb.x, bomb.y - (p * pixels), bombTexture, 9, context2D); // up
                            BlitSprite(bomb.x, bomb.y + (p * pixels), bombTexture, 9, context2D); // down
                        }
                    }
                    else if (frame < 24)
                    {
                        BlitSprite(bomb.x, bomb.y, bombTexture, 5, context2D); // midde
                        for (int p = 1; p <= bomb.power; p++)
                        {
                            BlitSprite(bomb.x - (p * pixels), bomb.y, bombTexture, 7, context2D); // left
                            BlitSprite(bomb.x + (p * pixels), bomb.y, bombTexture, 7, context2D); // right
                            BlitSprite(bomb.x, bomb.y - (p * pixels), bombTexture, 6, context2D); // up
                            BlitSprite(bomb.x, bomb.y + (p * pixels), bombTexture, 6, context2D); // down
                        }
                    }
                    else
                    {
                        BlitSprite(bomb.x, bomb.y, bombTexture, 2, context2D); // midde
                        for (int p = 1; p <= bomb.power; p++)
                        {
                            BlitSprite(bomb.x - (p * pixels), bomb.y, bombTexture, 4, context2D); // left
                            BlitSprite(bomb.x + (p * pixels), bomb.y, bombTexture, 4, context2D); // right
                            BlitSprite(bomb.x, bomb.y - (p * pixels), bombTexture, 3, context2D); // up
                            BlitSprite(bomb.x, bomb.y + (p * pixels), bombTexture, 3, context2D); // down
                        }
                    }
                }
            }
        }
        #endregion

        #region Helpers
        private Bitmap BitmapFromFile(string file)
        {
            var source = TextureLoader.LoadBitmap(graphics.WICFactory, file);
            var bitmap = Bitmap.FromWicBitmap(graphics.ContextDirect2D, source);

            return bitmap;
        }

        private void Blit(int x, int y, Bitmap texture, DeviceContext context2D)
        {
            if (texture == null) return;

            context2D.DrawBitmap(texture, new RectangleF(x, y, x + texture.Size.Width, y + texture.Size.Height), 1.0f, BitmapInterpolationMode.Linear);
        }

        private void BlitSprite(int x, int y, Bitmap texture, int index, DeviceContext context2D)
        {
            if (texture == null) return;

            int width = (int)texture.Size.Width / pixels;
            int xpos = (index % width) * pixels;
            int ypos = index > 0 ? (index / width) * pixels : 0;

            context2D.DrawBitmap(texture, new RectangleF(x, y, x + pixels, y + pixels), 1.0f, BitmapInterpolationMode.Linear, new RectangleF(xpos, ypos, xpos + pixels, ypos + pixels));
        }

        void BlitText(int index, DeviceContext context2D)
        {
            context2D.DrawBitmap(textTexture, new RectangleF(272, 176, 272 + 265, 176 + 64), fade, BitmapInterpolationMode.Linear, new RectangleF(0, index * 64, 265, 64));
        }

        void BlitText(int index, int x, int y, DeviceContext context2D)
        {
            context2D.DrawBitmap(textTexture, new RectangleF(x, y, x + 265, y + 64), 1.0f, BitmapInterpolationMode.Linear, new RectangleF(0, index * 64, 265, 64));
        }

        bool box(int x, int y, int x1, int y1, int x2, int y2)
        {
            if (x >= x1 && x <= x2 && y >= y1 && y <= y2) return true;

            return false;
        }
        #endregion

        void DrawText(DeviceContext context2D)
        {
            if (showStart)
            {
                BlitText(0, context2D);

                fade -= 0.01f;

                if (fade <= 0)
                {
                    fade = 1.0f;
                    showStart = false;
                }
            }

            if (showGameOver)
            {
                BlitText(2, context2D);

                fade -= 0.01f;

                if (fade <= 0)
                {
                    fade = 1.0f;
                    showGameOver = false;

                    //gameStatus = GameStatus.Menu;
                }
            }
        }
    }
}
