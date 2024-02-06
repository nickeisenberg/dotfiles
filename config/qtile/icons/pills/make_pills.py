import matplotlib.pyplot as plt
import numpy as np


class PillIcon:
    def __init__(self, background, foreground):
        self.background = background
        self.foreground = foreground


    def left_pill(self, x=np.linspace(-1, 0, 100), r=1, show=True, **kwargs):
        return self._pill(x=x, r=r, show=show, shape="left", **kwargs)

    def right_pill(self, x=np.linspace(0, 1, 100), r=1, show=True, **kwargs):
        return self._pill(x=x, r=r, show=show, shape="right", **kwargs)

    @staticmethod
    def quater_circle(x, r):
        return np.sqrt(r ** 2 - x ** 2)
    
    def _pill(self, x, r, shape, show=True, **kwargs):
        y_pos = self.quater_circle(x, r)
        y_neg = -self.quater_circle(x, r)

        fig = plt.figure(**kwargs)
        plt.plot(x, y_pos, c=self.foreground)
        plt.plot(x, y_neg, c=self.foreground)

        plt.fill_between(x, y_pos, color=self.foreground, alpha=1)
        plt.fill_between(x, y_neg, color=self.foreground, alpha=1)

        plt.fill_between(x, y_pos, y2=1, color=self.background, alpha=1)
        plt.fill_between(x, y_neg, y2=-1, color=self.background, alpha=1)
        
        if shape == "left":
            plt.fill_between(
                np.linspace(-2, -1, 100), 
                np.repeat(1, 100), 
                color=self.background, 
                alpha=1
            )
            plt.fill_between(
                np.linspace(-2, -1, 100), 
                -np.repeat(1, 100), 
                color=self.background, 
                alpha=1
            )

            plt.xlim(-2, 1)

        if shape == "right":
            plt.fill_between(
                np.linspace(1, 2, 100), 
                np.repeat(1, 100), 
                color=self.background, 
                alpha=1
            )
            plt.fill_between(
                np.linspace(1, 2, 100), 
                -np.repeat(1, 100), 
                color=self.background, 
                alpha=1
            )

            plt.xlim(-1, 2)

        if show:
            plt.show()
        else:
            return fig

background = '#191724'
background_alt = '#403d52'

pill = PillIcon(background=background, foreground=background_alt)

pill.left_pill(show=True, figsize=(5, 5))

pill.right_pill(show=True, figsize=(5, 5))











