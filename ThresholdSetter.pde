public class ThresholdSetter extends controlP5.Controller
{
    /*
     * The controller threshold value is accessed and set through getValue() and setValue()).
     * The controller also stores the position (in pixels) of the threshold line, and the signal-level values
     * at bottom and top of controller display.
     */
    PApplet parent;
    int backgroundColor = 0xff02344d;
    int chartColor = 0xff016c9e;
    int thresholdActivationIndicatorColor = 0xffE30202;
    protected int thresholdLineY = 0; // Threshold line position in pixels 
    protected int bufferSize = 512; // Sample size of internal signal buffer
    protected float minValue = 0; // Signal-level value at bottom of controller display 
    protected float maxValue = 1; // Signal-level value at top of controller display 
    protected float[] buffer = new float[bufferSize]; // Buffer of signal values
    protected boolean lastBufferSampleAboveThreshold = false;

    public ThresholdSetter(ControlP5 cp5, String name, PApplet parent)
    {
        super(cp5, name);
        this.parent = parent;
        parent.registerDispose(this);
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
                if (lastBufferSampleAboveThreshold) // Threshold activation indicator
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
        setValue(parent.map(thresholdLineY, 0, getHeight(), maxValue, minValue)); // Update the controller value based on the position of the threshold line and the controller's min/max range
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
            lastBufferSampleAboveThreshold = true;
        }
        else 
        { 
            lastBufferSampleAboveThreshold = false;
        }
        return distanceToThreshold;
    }

    protected void onDrag()
    {
        Pointer p1 = getPointer();
        float dif = parent.dist(p1.px(), p1.y(), p1.x(), p1.y());
        if (p1.y() > 0 && p1.y() < getHeight())
        {
            thresholdLineY = p1.y();
            updateControllerValue();
        }
    }

    public ThresholdSetter setColorBackground(int color)
    {
        backgroundColor = color;
        return this;
    }

    public ThresholdSetter setColorChart(int color)
    {
        chartColor = color;
        return this;
    }

    public ThresholdSetter setColorThresholdActivationIndicator(int color)
    {
        thresholdActivationIndicatorColor = color;
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
}
