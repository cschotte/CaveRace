using System;

namespace MapEdit
{
#if WINDOWS || XBOX
    static class Program
    {
        /// <summary>
        /// The main entry point for the application.
        /// </summary>
        static void Main(string[] args)
        {
            using (MapEditGame game = new MapEditGame())
            {
                game.Run();
            }
        }
    }
#endif
}

