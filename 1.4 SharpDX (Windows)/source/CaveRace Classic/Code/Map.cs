using System;
using System.IO;
using System.Collections.Generic;
using System.Threading.Tasks;
using Windows.Storage;
using Windows.ApplicationModel;
using Windows.Storage.Streams;

namespace CaveRace_Classic
{
    public class Map
    {
        private const int pixels = 32;
        private const int width = 25;
        private const int height = 13;

        public byte[,] background = new byte[width, height];
        public byte[,] stone = new byte[width, height];
        public byte[,] treasure = new byte[width, height];
        public byte[,] enemy = new byte[width, height];
        public byte[,] player = new byte[width, height];
        public byte[,] bomb = new byte[width, height];

        public int Width
        {
            get { return width; }
        }

        public int Height
        {
            get { return height; }
        }

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

        public async Task<bool> Load(string filename)
        {
            // http://msdn.microsoft.com/en-us/library/windows/apps/xaml/Hh758325.aspx

            StorageFolder storageFolder = Package.Current.InstalledLocation;
            StorageFile sampleFile = await storageFolder.GetFileAsync(@"Assets\Levels\" + filename + ".bin");
            
            var buffer = await FileIO.ReadBufferAsync(sampleFile);

            DataReader dataReader = DataReader.FromBuffer(buffer);

            for (int x = 0; x < width; x++)
            {
                for (int y = 0; y < height; y++)
                {
                    background[x, y] = dataReader.ReadByte();
                }
            }

            for (int x = 0; x < width; x++)
            {
                for (int y = 0; y < height; y++)
                {
                    stone[x, y] = dataReader.ReadByte();
                }
            }

            for (int x = 0; x < width; x++)
            {
                for (int y = 0; y < height; y++)
                {
                    treasure[x, y] = dataReader.ReadByte();
                }
            }

            for (int x = 0; x < width; x++)
            {
                for (int y = 0; y < height; y++)
                {
                    enemy[x, y] = dataReader.ReadByte();
                }
            }

            for (int x = 0; x < width; x++)
            {
                for (int y = 0; y < height; y++)
                {
                    player[x, y] = dataReader.ReadByte();
                }
            }

            for (int x = 0; x < width; x++)
            {
                for (int y = 0; y < height; y++)
                {
                    bomb[x, y] = 0;
                }
            }
          
            return true;
        }

    }
}
