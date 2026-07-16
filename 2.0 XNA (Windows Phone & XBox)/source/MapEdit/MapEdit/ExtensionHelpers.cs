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
    public static class ExtensionHelpers
    {
        public static int CountTiles(this Texture2D texture)
        {
            int w = texture.Width / 32;
            int h = texture.Height / 32;
            int m = w * h;

            return m;
        }
    }
}
