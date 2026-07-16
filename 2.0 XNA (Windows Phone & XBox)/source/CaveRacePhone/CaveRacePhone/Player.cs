using System;

namespace CaveRace
{
    public class Player
    {
        public int id = 1;

        public int lives = 4;
        public int energy = 9;
        public int bombs = 1;
        public int power = 1;
        public int points = 0;
        public int levelId = 0;

        public int x = 0, y = 0;
        public int xmov = 0, ymov = 0;
    }
}
