using System;
using System.IO;
using System.Collections.Generic;
using Microsoft.Xna.Framework;

namespace CaveRace
{
    public class Map
    {
        private const int pixels = 32;
        public const int width = 25;
        public const int height = 13;

        public byte[,] background = new byte[width, height];
        public byte[,] stone = new byte[width, height];
        public byte[,] treasure = new byte[width, height];
        public byte[,] enemy = new byte[width, height];
        public byte[,] player = new byte[width, height];
        public byte[,] bomb = new byte[width, height];

        public Player GetPlayer()
        {
            Player myplayer = new Player();

            for (int x = 0; x < width; x++)
            {
                for (int y = 0; y < height; y++)
                {
                    if (player[x, y] == 1)
                    {
                        myplayer.x = x * pixels;
                        myplayer.y = y * pixels;
                    }
                }
            }

            return myplayer;
        }

        public List<Enemy> GetEnemys()
        {
            List<Enemy> enemys = new List<Enemy>();

            for (int x = 0; x < width; x++)
            {
                for (int y = 0; y < height; y++)
                {
                    if (enemy[x, y] > 0)
                    {
                        Enemy myEnemy = new Enemy();
                        myEnemy.i = enemy[x, y];
                        myEnemy.x = x * pixels;
                        myEnemy.y = y * pixels;

                        enemys.Add(myEnemy);
                    }
                }
            }

            return enemys;
        }

        public bool Load(string filename)
        {
            try
            {
                using (var stream = TitleContainer.OpenStream("./Content/Levels/" + filename + ".bin"))
                {
                    using (var sr = new BinaryReader(stream))
                    {
                        for (int x = 0; x < width; x++)
                        {
                            for (int y = 0; y < height; y++)
                            {
                                background[x, y] = sr.ReadByte();
                            }
                        }

                        for (int x = 0; x < width; x++)
                        {
                            for (int y = 0; y < height; y++)
                            {
                                stone[x, y] = sr.ReadByte();
                            }
                        }

                        for (int x = 0; x < width; x++)
                        {
                            for (int y = 0; y < height; y++)
                            {
                                treasure[x, y] = sr.ReadByte();
                            }
                        }

                        for (int x = 0; x < width; x++)
                        {
                            for (int y = 0; y < height; y++)
                            {
                                enemy[x, y] = sr.ReadByte();
                            }
                        }

                        for (int x = 0; x < width; x++)
                        {
                            for (int y = 0; y < height; y++)
                            {
                                player[x, y] = sr.ReadByte();
                            }
                        }

                        for (int x = 0; x < width; x++)
                        {
                            for (int y = 0; y < height; y++)
                            {
                                bomb[x, y] = 0;
                            }
                        }
                    }
                }
            }
            catch (Exception)
            {
                return false;
            }

            return true;
        }

    }
}
