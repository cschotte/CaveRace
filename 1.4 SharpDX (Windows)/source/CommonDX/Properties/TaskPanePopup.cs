using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Windows.UI.Xaml;
using Windows.UI.Xaml.Controls;
using Windows.UI.Xaml.Controls.Primitives;
using Windows.UI.Xaml.Media.Animation;

namespace Counter.Helpers
{
    public class TaskPanePopup
    {

        private Popup _popup;
        public FrameworkElement TaskPane { get; private set; }

        public TaskPanePopup(FrameworkElement taskPane)
        {
            if (double.IsNaN(taskPane.Width))
            {
                throw new ArgumentException("TaskPane width must be set");
            }
            this.TaskPane = taskPane;

            this._popup = new Popup
            {
                IsLightDismissEnabled = true,
                ChildTransitions = new TransitionCollection(),
                Child = taskPane,
            };

            this._popup.ChildTransitions.Add(new PaneThemeTransition
            {
                Edge = EdgeTransitionLocation.Right
            });
        }

        public void Show()
        {
            this.TaskPane.Height = Window.Current.Bounds.Height;
            this._popup.SetValue(
                    Canvas.LeftProperty,
                    Window.Current.Bounds.Width - this.TaskPane.Width
            );
            this._popup.IsOpen = true;
        }

    }

}
