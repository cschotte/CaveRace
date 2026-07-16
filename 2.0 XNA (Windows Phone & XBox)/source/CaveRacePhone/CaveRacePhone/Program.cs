using System;

namespace CaveRace
{
#if WINDOWS || XBOX
    static class Program
    {
        /// <summary>
        /// The main entry point for the application.
        /// </summary>
        static void Main(string[] args)
        {
            using (CaveRaceGame game = new CaveRaceGame())
            {
                game.Run();
            }
        }
    }
#endif
}

