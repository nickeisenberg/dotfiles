import matplotlib.pyplot as plt
import numpy as np

#-Rose Pine Colors---------------------------------
background = "#191724"
background_alt = "#2E2B46"
foreground = "#e0def4"
foreground = "#808080"
selected = "#31748f"
urgent = "#eb6f92"
active = "#9ccfd8"
widget_text_color = "#ffffff"
#--------------------------------------------------

class PillIcon:

    def __init__(self, background, foreground):
        self.background = background
        self.foreground = foreground

    @staticmethod
    def quater_circle(x, r):
        return r * np.sqrt(1 - x ** 2)
    
    def left_pill(self, r, show=True, **kwargs):
        x = np.linspace(-1, 0, 1000)
        y_pos = self.quater_circle(x, r)
        y_neg = -self.quater_circle(x, r)

        fig = plt.figure(**kwargs)
        plt.plot(x, y_pos, c=self.foreground)
        plt.plot(x, y_neg, c=self.foreground)
        plt.fill_between(x, y_pos, color=self.foreground, alpha=1)
        plt.fill_between(x, y_neg, color=self.foreground, alpha=1)
        plt.fill_between(x, y_pos, y2=1, color=self.background, alpha=1)
        plt.fill_between(x, y_neg, y2=-1, color=self.background, alpha=1)

        if show:
            plt.show()
        else:
            return fig

    def right_pill(self, r, show=True, **kwargs):
        x = np.linspace(0, 1, 1000)

        y_pos = self.quater_circle(x, r)
        y_neg = -self.quater_circle(x, r)
        
        fig = plt.figure(**kwargs)
        plt.plot(x, y_pos, c=self.foreground)
        plt.plot(x, y_neg, c=self.foreground)
        plt.fill_between(x, y_pos, color=self.foreground, alpha=1)
        plt.fill_between(x, y_neg, color=self.foreground, alpha=1)
        plt.fill_between(x, y_pos, y2=1, color=self.background, alpha=1)
        plt.fill_between(x, y_neg, y2=-1, color=self.background, alpha=1)

        if show:
            plt.show()
        else:
            return fig
     
pill = PillIcon(background=background, foreground=background_alt)

pill.left_pill(1, figsize=(5, 5))
pill.right_pill(1, figsize=(5, 5))

