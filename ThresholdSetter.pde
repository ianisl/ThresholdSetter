public class ThresholdSetter extends controlP5.Controller
{
    /*
     * The controller threshold value is accessed and set through getValue() and setValue()).
     * The controller also stores the position (in pixels) of the threshold line, and the signal-level values
     * at bottom and top of controller display.
     */
    PApplet applet;
    protected int backgroundColor = 0xff02344d;
    protected int chartColor = 0xff016c9e;
    protected int thresholdActivationIndicatorColor = 0xffE30202;
    protected int thresholdLineY = 0; // Threshold line position in pixels 
    protected int bufferSize = 512; // Sample size of internal signal buffer
    protected float minValue = 0; // Signal-level value at bottom of controller display 
    protected float maxValue = 1; // Signal-level value at top of controller display 
    protected float[] buffer = new float[bufferSize]; // Buffer of signal values
    public boolean isLastDetectionPositive = false;
    protected int previousBufferSampleAboveThresholdDetectionTime = 0;
    protected int decayTime = 500; // Samples detected during a time window equal to decayTime after the last detection will be marked as negative, even if they are above threshold

    public ThresholdSetter(ControlP5 cp5, String name, PApplet applet)
    {
        super(cp5, name);
        this.applet = applet;
        if (getValue() > maxValue) 
        {
            setValue(maxValue);
        }
        else if (getValue() < minValue) 
        {
            setValue(minValue);
        }
        setView(new ControllerView<ThresholdSetter>() // replace the default view with a custom view.
        {
            public void display(PApplet p, ThresholdSetter b)
            {
                p.strokeWeight(1);
                p.fill(backgroundColor); // draw button background
                p.stroke(backgroundColor);
                p.rect(0, 0, getWidth(), getHeight());
                p.stroke(255); // Threshold line 
                p.line(0, thresholdLineY, width, thresholdLineY);
                p.noFill(); // Draw buffer chart
                p.stroke(chartColor);
                p.beginShape();
                for (int i = bufferSize - 1; i >= 0; i--)
                {
                    p.vertex(p.map(i, bufferSize - 1, 0, getWidth(), 0), p.map(buffer[i], minValue, maxValue, getHeight(), 0));
                }
                p.endShape();
                p.fill(255); // draw the custom label 
                Label caption = b.getCaptionLabel();
                caption.style().marginTop = getHeight() + 5;
                caption.draw(p);
                if (isLastDetectionPositive) // Threshold activation indicator
                {
                    p.stroke(thresholdActivationIndicatorColor);
                    p.fill(thresholdActivationIndicatorColor);
                    p.rect(caption.getWidth() + 5, getHeight() + 5, 5, 5);
                }
            }
        });
    }

    public ThresholdSetter setRange(float minValue, float maxValue)
    {
        if (minValue <= maxValue)
        {
            this.minValue = minValue;
            this.maxValue = maxValue;
            updateControllerValue();
        }
        else 
        {
            println("ThresholdSetter - warning: bad min/max values");
        }
        return this;
    }

    protected void updateControllerValue()
    {
        setValue(applet.map(thresholdLineY, 0, getHeight(), maxValue, minValue)); // Update the controller value based on the position of the threshold line and the controller's min/max range
    }

    public float getMinValue()
    {
        return minValue;
    }

    public float getMaxValue()
    {
        return maxValue;
    }

    public float addToBuffer(float sample)
    {
        System.arraycopy(buffer, 1, buffer, 0, bufferSize - 1);
        buffer[bufferSize - 1] = sample;
        float distanceToThreshold = sample - getValue();
        if (distanceToThreshold > 0) 
        { 
            // If we have a detection (a buffer sample above threshold)
            int bufferSampleAboveThresholdDetectionTime = applet.millis();
            if (bufferSampleAboveThresholdDetectionTime - previousBufferSampleAboveThresholdDetectionTime > decayTime)
            {
                // If we are outside decay window, this is a true positive detection
                previousBufferSampleAboveThresholdDetectionTime = bufferSampleAboveThresholdDetectionTime;
                isLastDetectionPositive = true;
            }
            else
            {
                // Sample is marked negative
                isLastDetectionPositive = false;
            }
        }
        else 
        { 
            isLastDetectionPositive = false;
        }
        return distanceToThreshold; // Return this in all cases
    }

    protected void onDrag()
    {
        Pointer p1 = getPointer();
        float dif = applet.dist(p1.px(), p1.y(), p1.x(), p1.y());
        if (p1.y() > 0 && p1.y() < getHeight())
        {
            thresholdLineY = p1.y();
            updateControllerValue();
        }
    }

    public ThresholdSetter setColorBackground(int backgroundColor)
    {
        this.backgroundColor = backgroundColor;
        return this;
    }

    public ThresholdSetter setColorChart(int chartColor)
    {
        this.chartColor = chartColor;
        return this;
    }

    public ThresholdSetter setColorThresholdActivationIndicator(int thresholdActivationIndicatorColor)
    {
        this.thresholdActivationIndicatorColor = thresholdActivationIndicatorColor;
        return this;
    }

    public ThresholdSetter setBufferSize(int bufferSize)
    {
        this.bufferSize = bufferSize;
        buffer = new float[bufferSize];
        return this;
    }

    public int getBufferSize()
    {
        return bufferSize;
    }

    public int getThresholdLineY()
    {
        return thresholdLineY;
    }

    public void setThresholdLineY(int thresholdLineY)
    {
        this.thresholdLineY = thresholdLineY;
    }

    public boolean isLastBufferSampleAboveThreshold()
    {
        return lastBufferSampleAboveThreshold;
    }

    public ThresholdSetter setDecayTime(int decayTime)
    {
        this.decayTime = decayTime;
    }
}

public class MinimThresholdSetter extends ThresholdSetter
{
    /* A ThresholdSetter fed with the mean level of a Minim stereo input.
     * The field 'lastSampleLevel' gives the distance of the last processed sample
     * to the signal level, if it is a truly position detection (ie if it was not)
     * detected too soon after a previous detection. Otherwise, 'lastSampleLevel'
     * will be equal to -1.
     */
    protected Minim minim;
    protected AudioInput audioInput;
    protected int minimBufferSize;
    public float lastSampleLevel; // By convention, = to distance above signal level is last detection is a truly position one, equal to -1 otherwise

    public MinimThresholdSetter(int minimBufferSize, ControlP5 cp5, String name, PApplet applet)
    {
        super(cp5, name, applet);
        this.minimBufferSize = minimBufferSize;
        applet.registerPre(this);
        applet.registerPost(this);
    }

    public void pre()
    {
        minim = new Minim(applet);
        audioInput = minim.getLineIn(Minim.STEREO, minimBufferSize); // add the mean level of the current buffer to ThresholdSetters' internal buffer
    }

    public void post()
    {
        lastSampleLevel = this.addToBuffer(audioInput.left.level()); // add the mean level of the current buffer to the MinimThresholdSetters' internal buffer
        if (!this.isLastDetectionPositive)
        {
            lastSampleLevel = -1;
        }
    }
}