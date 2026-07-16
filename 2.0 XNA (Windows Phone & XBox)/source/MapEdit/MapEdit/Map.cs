using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;

namespace MapEdit
{
    public class Map
    {
        public byte[,] background;
        public byte[,] stone;
        public byte[,] treasure;
        public byte[,] enemy;
        public byte[,] player;
        public byte[,] bomb;

        public int width = 0;
        public int height = 0;

        public Map(int width, int height)
        {
            if (width <= 0 || height <= 0) throw (new ArgumentOutOfRangeException());

            background = new byte[width, height];
            stone = new byte[width, height];
            treasure = new byte[width, height];
            enemy = new byte[width, height];
            player = new byte[width, height];
            bomb = new byte[width, height];

            this.width = width;
            this.height = height;
        }

        public bool Load(string filename)
        {
            try
            {
                string folder = Environment.GetFolderPath(Environment.SpecialFolder.Desktop);

                using (var stream = File.Open(folder + "\\" + filename, FileMode.Open))
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

        public bool Save(string filename)
        {
            try
            {
                string folder = Environment.GetFolderPath(Environment.SpecialFolder.Desktop);

                using (var stream = File.Create(folder + "\\" + filename))
                {
                    using (var sr = new BinaryWriter(stream))
                    {
                        for (int x = 0; x < width; x++)
                        {
                            for (int y = 0; y < height; y++)
                            {
                                sr.Write((byte)background[x, y]);
                            }
                        }

                        for (int x = 0; x < width; x++)
                        {
                            for (int y = 0; y < height; y++)
                            {
                                sr.Write((byte)stone[x, y]);
                            }
                        }

                        for (int x = 0; x < width; x++)
                        {
                            for (int y = 0; y < height; y++)
                            {
                                sr.Write((byte)treasure[x, y]);
                            }
                        }

                        for (int x = 0; x < width; x++)
                        {
                            for (int y = 0; y < height; y++)
                            {
                                sr.Write((byte)enemy[x, y]);
                            }
                        }

                        for (int x = 0; x < width; x++)
                        {
                            for (int y = 0; y < height; y++)
                            {
                                sr.Write((byte)player[x, y]);
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
