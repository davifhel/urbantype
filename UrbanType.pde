import controlP5.*;
import java.util.HashMap;
import java.util.ArrayList;
import java.io.File;

ControlP5 cp5;
TextCanvas canvas;
ControlPanel controlPanel;
HashMap<Character, Letter[]> letterMap;
PImage placeholder;

final int LETTER_HEIGHT = 100;  // Festgelegte Höhe für alle Buchstaben

void setup() {
  size(800, 600);
  cp5 = new ControlP5(this);
  canvas = new TextCanvas(width, height);
  controlPanel = new ControlPanel(cp5);
  letterMap = new HashMap<Character, Letter[]>();
  placeholder = loadImage("data/rest/!.png");
  placeholder.resize(placeholder.width * LETTER_HEIGHT / placeholder.height, LETTER_HEIGHT);

  loadLetters();
}

void draw() {
  background(255);
  canvas.display();
  controlPanel.display();}

void loadLetters() {
  String[] letters = {"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
                      "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"};

  for (String letter : letters) {
    File dir = new File(sketchPath("data/" + letter));
    if (!dir.exists()) {
      println("Directory does not exist: " + dir.getAbsolutePath());
      continue;
    }
    File[] files = dir.listFiles((dir1, name) -> name.toLowerCase().endsWith(".png"));
    if (files != null && files.length > 0) {
      Letter[] images = new Letter[files.length];
      for (int i = 0; i < files.length; i++) {
        PImage img = loadImage(files[i].getAbsolutePath());
        if (img == null) {
          println("Failed to load image: " + files[i].getAbsolutePath());
          continue;
        }
        images[i] = new Letter(img);
      }
      letterMap.put(letter.charAt(0), images);
    } else {
      println("No PNG files found in directory: " + dir.getAbsolutePath());
    }
  }
}

void keyPressed() {
  if (key == BACKSPACE) {
    canvas.removeLastLetter();
  } 
  else {
    canvas.addLetter(key, controlPanel.getCurrentSettings());
  }
  
  if (key == ENTER) {
    saveFrame("canva-####.png");
  }
}


class Letter {
  PImage img;

  Letter(PImage img) {
    // Skaliere das Bild auf die feste Höhe, behalte das Seitenverhältnis bei
    img.resize(img.width * LETTER_HEIGHT / img.height, LETTER_HEIGHT);
    this.img = img;
  }

  PImage getModifiedImage(float contrast, float hue, float saturation) {
    PImage modified = img.copy();
    
    // Apply contrast
    modified.loadPixels();
    for (int i = 0; i < modified.pixels.length; i++) {
      color c = modified.pixels[i];
      float r = red(c) / 255.0;
      float g = green(c) / 255.0;
      float b = blue(c) / 255.0;
      r = constrain((r - 0.5) * contrast + 0.5, 0, 1) * 255;
      g = constrain((g - 0.5) * contrast + 0.5, 0, 1) * 255;
      b = constrain((b - 0.5) * contrast + 0.5, 0, 1) * 255;
      modified.pixels[i] = color(r, g, b);
    }
    modified.updatePixels();

    // Apply hue and saturation
    modified.loadPixels();
    for (int i = 0; i < modified.pixels.length; i++) {
      color c = modified.pixels[i];
      float[] hsb = rgbToHsb(red(c), green(c), blue(c));
      hsb[0] = (hsb[0] + hue / 255.0) % 1.0;
      hsb[1] = constrain(hsb[1] * (saturation / 127.0), 0, 1);
      modified.pixels[i] = color(hsbToRgb(hsb[0], hsb[1], hsb[2]));
    }
    modified.updatePixels();

    return modified;
  }

  // Helper function to convert RGB to HSB
  float[] rgbToHsb(float r, float g, float b) {
    float[] hsb = new float[3];
    colorMode(HSB, 1.0);
    color c = color(r / 255.0, g / 255.0, b / 255.0);
    hsb[0] = hue(c);
    hsb[1] = saturation(c);
    hsb[2] = brightness(c);
    colorMode(RGB, 255);
    return hsb;
  }

  // Helper function to convert HSB to RGB
  color hsbToRgb(float h, float s, float b) {
    colorMode(HSB, 1.0);
    color c = color(h, s, b);
    colorMode(RGB, 255);
    return c;
  }
}

class TextCanvas {
  PImage buffer;
  int x, y;
  ArrayList<LetterPosition> letters;  // Liste zur Verfolgung der Buchstabenpositionen

  TextCanvas(int width, int height) {
    buffer = createImage(width, height, RGB);
    x = 0;
    y = 0;
    letters = new ArrayList<LetterPosition>();  // Initialisiere die Liste
  }

  void addLetter(char letter, float[] settings) {
    Letter[] lettersArray = letterMap.get(letter);
    PImage img;
    if (lettersArray != null && lettersArray.length > 0) {
      img = lettersArray[int(random(lettersArray.length))].getModifiedImage(settings[0], settings[1], settings[2]);
    } else {
      img = placeholder;
    }
    buffer.set(x, y, img);
    letters.add(new LetterPosition(x, y, img.width, img.height));  // Speichere die Position und Größe des Buchstabens
    x += img.width;
    if (x >= width-20) {
      x = 0;
      y += img.height;
    }
  }

  void removeLastLetter() {
    if (letters.size() > 0) {
      LetterPosition lastLetter = letters.remove(letters.size() - 1);  // Entferne den letzten Buchstaben aus der Liste
      for (int i = lastLetter.x; i < lastLetter.x + lastLetter.width; i++) {
        for (int j = lastLetter.y; j < lastLetter.y + lastLetter.height; j++) {
          buffer.set(i, j, color(0));  // Leere den Bereich des letzten Buchstabens
        }
      }
      x = lastLetter.x;  // Setze die x-Position zurück
      y = lastLetter.y;  // Setze die y-Position zurück, falls nötig
    }
  }

  void display() {
    image(buffer, 0, 0);
  }
}

class LetterPosition {
  int x, y, width, height;

  LetterPosition(int x, int y, int width, int height) {
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
  }
}

class ControlPanel {
  ControlP5 cp5;
  float[] settings;

  ControlPanel(ControlP5 cp5) {
    this.cp5 = cp5;
    settings = new float[3];
    createControls();
  }

  void createControls() {
    cp5.addSlider("contrast")
       .setPosition(10, height - 30)
       .setRange(0, 2)
       .setValue(0)
       .plugTo(this, "setContrast");

    cp5.addSlider("hue")
       .setPosition(150, height - 30)
       .setRange(0, 255)
       .setValue(0)
       .plugTo(this, "setHue");

    cp5.addSlider("saturation")
       .setPosition(290, height - 30)
       .setRange(0, 255)
       .setValue(0)
       .plugTo(this, "setSaturation");
  }

  void setContrast(float value) {
    settings[0] = value;
  }

  void setHue(float value) {
    settings[1] = value;
  }

  void setSaturation(float value) {
    settings[2] = value;
  }

  float[] getCurrentSettings() {
    return settings;
  }

  void display() {
    cp5.draw();
  }
}
