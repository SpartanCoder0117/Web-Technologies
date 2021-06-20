import java.awt.*;
import java.applet.*;

public class MiMelodia extends Applet
{
	AudioClip ac;
	public void init()
	{
		ac = getAudioClip(getCodeBase(),"melodia.wav");
    }	

    public void paint(Graphics g)
    {
		g.drawString("Reproduciendo",25,25);
	}

	public void start()
	{
		ac.loop();
	}

	public void stop()
	{
		ac.stop();
	}
}
	