using System;
using System.Collections.Generic;
using System.Linq;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Audio;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.GamerServices;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using Microsoft.Xna.Framework.Media;
using System.Reflection;

namespace MapEdit
{
    public class MapEditGame : Microsoft.Xna.Framework.Game
    {
        private const int pixels = 32;

        #region Fields
        // Graphics
        GraphicsDeviceManager graphics;
        SpriteBatch spriteBatch;

        // Game Sprites
        Texture2D backgroundTexture;
        Texture2D enemyTexture;
        Texture2D stoneTexture;
        Texture2D playerTexture;
        Texture2D tresureTexture;

        Texture2D desertTexture;
        Texture2D forestTexture;
        Texture2D winterTexture;
        Texture2D lavaTexture;

        // Input
        KeyboardState old_KeyboardState;
        MouseState old_MouseState;

        // MapEdit
        Map map = new Map(Properties.Settings.Default.MapWidth, Properties.Settings.Default.MapHeight);
        
        Texture2D[] bars = new Texture2D[5];
        Texture2D selectTexture;

        int xbar = 0;
        int ybar = 0;
        int ibar = 0;
        #endregion

        #region Initialization
        public MapEditGame()
        {
            graphics = new GraphicsDeviceManager(this);
            graphics.PreferredBackBufferWidth = Properties.Settings.Default.ScreenWidth;
            graphics.PreferredBackBufferHeight = Properties.Settings.Default.ScreenHeight;

            IsMouseVisible = true;

            old_KeyboardState = Keyboard.GetState();

            Content.RootDirectory = "Content";
        }
        
        protected override void Initialize()
        {
            AssemblyName name = this.GetType().Assembly.GetName();
            this.Window.Title = string.Format("{0} ({1})", Properties.Resources.ApplicationName, name.Version);

            map.Load(Properties.Settings.Default.MapFileName);

            base.Initialize();
        }

        protected override void OnExiting(object sender, EventArgs args)
        {
            map.Save(Properties.Settings.Default.MapFileName);

            base.OnExiting(sender, args);
        }
        #endregion

        #region Load Content
        protected override void LoadContent()
        {
            spriteBatch = new SpriteBatch(GraphicsDevice);

            // Game Sprites
            enemyTexture = Content.Load<Texture2D>("Sprites/Enemy");
            stoneTexture = Content.Load<Texture2D>("Sprites/Stone");
            playerTexture = Content.Load<Texture2D>("Sprites/Player");
            tresureTexture = Content.Load<Texture2D>("Sprites/Treasure");

            desertTexture = Content.Load<Texture2D>("Sprites/desert");
            forestTexture = Content.Load<Texture2D>("Sprites/forest");
            winterTexture = Content.Load<Texture2D>("Sprites/winter");
            lavaTexture = Content.Load<Texture2D>("Sprites/lava");

            backgroundTexture = winterTexture;

            // MapEdit
            selectTexture = Content.Load<Texture2D>("Sprites/Select");

            // MapEdit Bar
            bars[0] = backgroundTexture;
            bars[1] = stoneTexture;
            bars[2] = tresureTexture;
            bars[3] = enemyTexture;
            bars[4] = playerTexture;
        }
        #endregion

        #region Update
        protected override void Update(GameTime gameTime)
        {
            #region GamePad
            if (GamePad.GetState(PlayerIndex.One).Buttons.Back == ButtonState.Pressed) this.Exit();
            #endregion

            #region Keyboard
            KeyboardState ks = Keyboard.GetState();

            if (ks.IsKeyDown(Keys.Left))
            {
                if (++xbar > 0) xbar = 0;
            }

            if (ks.IsKeyDown(Keys.Right))
            {
                int m = bars[ybar].CountTiles();

                if(m > map.width)
                    if (--xbar < ((m * pixels) - graphics.PreferredBackBufferWidth) * -1)
                        xbar = ((m * pixels) - graphics.PreferredBackBufferWidth) * -1;
            }

            if (ks.IsKeyDown(Keys.Down) && !old_KeyboardState.IsKeyDown(Keys.Down))
            {
                if (++ybar >= bars.Count()) ybar = bars.Count() - 1;

                xbar = 0;
                ibar = 0;
            }

            if (ks.IsKeyDown(Keys.Up) && !old_KeyboardState.IsKeyDown(Keys.Up))
            {
                if (--ybar < 0) ybar = 0;

                xbar = 0;
                ibar = 0;
            }

            if (ks.IsKeyDown(Keys.D1) && !old_KeyboardState.IsKeyDown(Keys.D1))
            {
                backgroundTexture = desertTexture;
                bars[0] = backgroundTexture;
            }

            if (ks.IsKeyDown(Keys.D2) && !old_KeyboardState.IsKeyDown(Keys.D2))
            {
                backgroundTexture = winterTexture;
                bars[0] = backgroundTexture;
            }

            if (ks.IsKeyDown(Keys.D3) && !old_KeyboardState.IsKeyDown(Keys.D3))
            {
                backgroundTexture = forestTexture;
                bars[0] = backgroundTexture;
            }

            if (ks.IsKeyDown(Keys.D4) && !old_KeyboardState.IsKeyDown(Keys.D4))
            {
                backgroundTexture = lavaTexture;
                bars[0] = backgroundTexture;
            }

            if (ks.IsKeyDown(Keys.S))
            {
                if (!old_KeyboardState.IsKeyDown(Keys.S))
                {
                    map.Save(Properties.Settings.Default.MapFileName);
                }
            }

            old_KeyboardState = ks;
            #endregion

            #region Mouse
            MouseState ms = Mouse.GetState();

            if (ms.Y <= map.height * pixels)
            {
                if (ms.LeftButton == ButtonState.Pressed)
                {
                    int x = ms.X / pixels;
                    int y = ms.Y / pixels;

                    if (x < 0) x = 0;
                    if (x > map.width) x = map.width - 1;

                    if (y < 0) y = 0;
                    if (y > map.height) y = map.height - 1;

                    switch (ybar)
                    {
                        case 0:
                            map.background[x, y] = (byte)ibar;
                            break;

                        case 1:
                            map.stone[x, y] = (byte)ibar;
                            break;

                        case 2:
                            map.treasure[x, y] = (byte)ibar;
                            break;

                        case 3:
                            map.enemy[x, y] = (byte)ibar;
                            break;

                        case 4:
                            map.player[x, y] = (byte)ibar;
                            break;

                        case 5:
                            map.bomb[x, y] = (byte)ibar;
                            break;
                    }
                }
            }

            if (ms.Y < 464 && ms.Y >= 432)
            {
                if (ms.LeftButton == ButtonState.Pressed)
                {
                    ibar = (ms.X + (xbar * -1)) / pixels;

                    int m = bars[ybar].CountTiles();

                    if (ibar >= m) ibar = m - 1;
                }
            }

            old_MouseState = ms;
            #endregion

            base.Update(gameTime);
        }
        #endregion

        #region Draw
        protected override void Draw(GameTime gameTime)
        {
            GraphicsDevice.Clear(Color.Black);

            spriteBatch.Begin();

            DrawMap(backgroundTexture, map.background, true);
            DrawMap(tresureTexture, map.treasure, false);
            DrawMap(stoneTexture, map.stone, false);
            DrawMap(playerTexture, map.player, false);
            DrawMap(enemyTexture, map.enemy, false);

            DrawBar(bars[ybar]);

            spriteBatch.End();

            base.Draw(gameTime);
        }

        void DrawMap(Texture2D texture, byte[,] items, bool first)
        {
            for (int y = 0; y < map.height; y++)
                for (int x = 0; x < map.width; x++)
                {
                    if (items[x, y] != 0 || first)
                        BlitSprite(x * pixels, y * pixels, texture, items[x, y], pixels);
                }
        }

        void DrawBar(Texture2D texture)
        {
            int m = texture.CountTiles();

            for (int i = 0; i < m; i++)
            {
                BlitSprite((i * pixels) + xbar, 432, texture, i, pixels);
            }

            BlitSprite((ibar * pixels) + xbar, 432, selectTexture, 0, pixels);
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

            spriteBatch.Draw(texture, new Vector2(x, y), new Rectangle(xpos, ypos, pixels, pixels), Color.White);
        }
        #endregion
    }
}
