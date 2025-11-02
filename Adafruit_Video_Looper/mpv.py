"""Implementation of MPV video player."""
import os
import subprocess
import time
import pygame

class MPVPlayer:
    """Class to handle video playback using the mpv video player."""

    def __init__(self, config):
        """Create an instance of a video player that runs mpv in the background."""
        self._process = None
        # Get list of supported file extensions.
        self._extensions = config.get('mpv', 'extensions') \
                               .translate(str.maketrans('', '', ' \t\r\n.')) \
                               .split(',')
        # Get extra arguments from config.
        self._extra_args = config.get('mpv', 'extra_args').split()
        # Store pygame display state
        self._pygame_active = False

    def supported_extensions(self):
        """Return list of supported file extensions."""
        return self._extensions

    def play(self, movie, loop=None, **kwargs):
        """Play the provided movie file, returning True if file was found/played.
        Loop parameter controls repetition: None = use movie.repeats, -1 = infinite,
        >0 = loop that many times, 0 = play once (no loop).
        """
        # Get the file path from the movie object.
        movie_path = movie.target if hasattr(movie, 'target') else movie

        # Check if the file exists and is accessible.
        if not os.path.exists(movie_path):
            return False

        # Quit pygame display to give mpv exclusive access
        if pygame.display.get_init():
            pygame.display.quit()
            self._pygame_active = True
            time.sleep(0.1)  # Give display time to release

        # Build up the mpv command line arguments.
        args = ['mpv']
        args.extend(self._extra_args)

        # Handle loop parameter
        if loop is None:
            loop = movie.repeats if hasattr(movie, 'repeats') else 1

        if loop <= -1:
            args.append('--loop=inf')  # Infinite loop for this video
        elif loop > 1:
            # mpv's --loop=N means play 1 time + loop N additional times
            # So we subtract 1 to get the desired number of total plays
            args.append('--loop={0}'.format(loop - 1))
        # loop == 0 or 1 means play once, no loop flag needed

        args.append(movie_path)

        # Run mpv process - stdout to /dev/null, but let stderr go to logs
        self._process = subprocess.Popen(args,
                                       stdout=open(os.devnull, 'wb'))

        # Wait for the process to start
        time.sleep(0.5)

        # Return True to indicate success
        return True

    def is_playing(self):
        """Return True if the video is still playing."""
        if self._process is None:
            return False
        return self._process.poll() is None

    def stop(self, block_timeout_sec=0):
        """Stop the current video playing."""
        # Stop the mpv process if it's running.
        if self._process is not None and self._process.poll() is None:
            # First try sending a quit command through a SIGTERM signal.
            self._process.terminate()
            # If a blocking timeout was specified, wait up to that amount of time
            # for the process to stop.
            if block_timeout_sec > 0:
                self._process.wait(timeout=block_timeout_sec)
            # Kill the process if it's still running.
            if self._process.poll() is None:
                self._process.kill()
            self._process = None

        # Reinitialize pygame display if we quit it earlier
        if self._pygame_active and not pygame.display.get_init():
            pygame.display.init()
            pygame.mouse.set_visible(False)
            self._pygame_active = False

    @staticmethod
    def can_loop_count():
        """Return true if the player can track loop count."""
        return False


def create_player(config, **kwargs):
    """Create new video player based on mpv."""
    return MPVPlayer(config) 