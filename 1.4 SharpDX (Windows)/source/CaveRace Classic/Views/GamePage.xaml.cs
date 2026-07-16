using CommonDX;
using Windows.Graphics.Display;
using Windows.System;
using Windows.UI.Xaml;
using Windows.UI.Xaml.Controls;
using Windows.UI.Xaml.Controls.Primitives;
using Windows.UI.Xaml.Media;
using Windows.UI.Xaml.Navigation;

namespace CaveRace_Classic
{
    public sealed partial class GamePage : Page
    {
        private DeviceManager deviceManager;
        private ImageBrush d2dBrush;
        private SurfaceImageSourceTarget d2dTarget;

        private MainRenderer mainRenderer;

        public GamePage()
        {
            this.InitializeComponent();

            Windows.UI.Core.CoreWindow.GetForCurrentThread().KeyDown += GamePage_KeyDown;
        }

        void GamePage_KeyDown(Windows.UI.Core.CoreWindow sender, Windows.UI.Core.KeyEventArgs args)
        {
            if (args.VirtualKey == VirtualKey.Space) mainRenderer.fireAction = MainRenderer.Keys.Bomb;

            if (args.VirtualKey == VirtualKey.Left) mainRenderer.moveAction = MainRenderer.Keys.Left;
            if (args.VirtualKey == VirtualKey.Right) mainRenderer.moveAction = MainRenderer.Keys.Right;
            if (args.VirtualKey == VirtualKey.Up) mainRenderer.moveAction = MainRenderer.Keys.Up;
            if (args.VirtualKey == VirtualKey.Down) mainRenderer.moveAction = MainRenderer.Keys.Down;

            args.Handled = true;
        }

        protected override void OnNavigatedTo(NavigationEventArgs e)
        {
            d2dBrush = new ImageBrush();
            d2dRectangle.Fill = d2dBrush;

            mainRenderer = new MainRenderer(d2dRectangle, root);
            deviceManager = new DeviceManager();

            int pixelWidth = (int)(d2dRectangle.Width * DisplayProperties.LogicalDpi / 96.0);
            int pixelHeight = (int)(d2dRectangle.Height * DisplayProperties.LogicalDpi / 96.0);

            d2dTarget = new SurfaceImageSourceTarget(pixelWidth, pixelHeight);
            d2dBrush.ImageSource = d2dTarget.ImageSource;
            d2dTarget.OnRender += mainRenderer.Render;

            deviceManager.OnInitialize += d2dTarget.Initialize;
            deviceManager.OnInitialize += mainRenderer.Initialize;
            deviceManager.Initialize(DisplayProperties.LogicalDpi);

            // Setup rendering callback
            CompositionTarget.Rendering += CompositionTarget_Rendering;
        }

        void CompositionTarget_Rendering(object sender, object e)
        {
            d2dTarget.RenderAll();
        }

        private void Button_Click(object sender, Windows.UI.Xaml.RoutedEventArgs e)
        {
            var b = sender as RepeatButton;

            switch (b.Tag as string)
            {
                case "Bomb":
                    mainRenderer.fireAction = MainRenderer.Keys.Bomb;
                    break;

                case "Up":
                    mainRenderer.moveAction = MainRenderer.Keys.Up;
                    break;

                case "Down":
                    mainRenderer.moveAction = MainRenderer.Keys.Down;
                    break;

                case "Left":
                    mainRenderer.moveAction = MainRenderer.Keys.Left;
                    break;

                case "Right":
                    mainRenderer.moveAction = MainRenderer.Keys.Right;
                    break;
            }
        }
    }
}
