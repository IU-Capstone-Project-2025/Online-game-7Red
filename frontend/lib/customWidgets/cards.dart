import 'package:flutter/material.dart';

import '../data/styles.dart';

// Class for central card in GamePage
class CentralCardWidget extends StatelessWidget {
  final String card;
  Color color = invisColor;

  CentralCardWidget({super.key, required this.card});

  // Function to set color of card
  void setColor() {
    switch (card[0]) {
      case 'R':
        color = redCard;
        break;
      case 'O':
        color = orangeCard;
        break;
      case 'Y':
        color = yellowCard;
        break;
      case 'G':
        color = greenCard;
        break;
      case 'B':
        color = blueCard;
        break;
      case 'I':
        color = indigoCard;
        break;
      case 'V':
        color = violetCard;
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    setColor();
    return Container(
      height: 76,
      width: 54,
      decoration:  BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: grey3A3A3AColor, width: 1.5),
      ),
      child: Center(
        // Add additional line to card for prettier look
        child: Container(
          height: 69,
          width: 47,
          decoration:  BoxDecoration(
            color: invisColor,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: Colors.white, width: 1.5),
          ),
          child: Center(
            child: Text(
              // If == 0 it means that it is initial red card without number
              card[1] == '0' ? '' : card[1],
              style: cardNumStyle,
            ),
          ),
        ),
      ),
    );
  }
}

// Class for cards in hand in GamePage
class HandCardWidget extends StatelessWidget {
  final String card;
  Color color = invisColor;

  HandCardWidget({super.key, required this.card});

  // Function to set color of card
  void setColor() {
    switch (card[0]) {
      case 'R':
        color = redCard;
        break;
      case 'O':
        color = orangeCard;
        break;
      case 'Y':
        color = yellowCard;
        break;
      case 'G':
        color = greenCard;
        break;
      case 'B':
        color = blueCard;
        break;
      case 'I':
        color = indigoCard;
        break;
      case 'V':
        color = violetCard;
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    setColor();
    return Container(
      height: 95,
      width: 64,
      decoration:  BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: grey3A3A3AColor, width: 1.5),
      ),
      child: Center(
        // Add additional line to card for prettier look
        child: Container(
          height: 88,
          width: 57,
          decoration:  BoxDecoration(
            color: invisColor,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: Colors.white, width: 1.5),
          ),
          child: Center(
            child: Text(
              card[1],
              style: cardNumStyle,
            ),
          ),
        ),
      ),
    );
  }
}

// Class for left player's card in GamePage
class LeftCardWidget extends StatelessWidget {
  final String card;
  Color color = invisColor;

  LeftCardWidget({super.key, required this.card});


  // Function to set color of card
  void setColor() {
    switch (card[0]) {
      case 'R':
        color = redCard;
        break;
      case 'O':
        color = orangeCard;
        break;
      case 'Y':
        color = yellowCard;
        break;
      case 'G':
        color = greenCard;
        break;
      case 'B':
        color = blueCard;
        break;
      case 'I':
        color = indigoCard;
        break;
      case 'V':
        color = violetCard;
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    setColor();
    return Container(
      height: 54,
      width: 76,
      decoration:  BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: grey3A3A3AColor, width: 1.5),
      ),
      child: Center(
        // Add additional line to card for prettier look
        child: Container(
          height: 47,
          width: 69,
          decoration:  BoxDecoration(
            color: invisColor,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: Colors.white, width: 1.5),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(padding: const EdgeInsets.only(left: 14.4)),
                // Rotate card for get an illusion that it is flipped and it is another person's card
                Transform.rotate(
                  angle: 1.57,
                  child: Text(
                    card[1] == '0' ? '' : card[1],
                    style: otherCardNumStyle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Class for right player's card in GamePage
class RightCardWidget extends StatelessWidget {
  final String card;
  Color color = invisColor;

  RightCardWidget({super.key, required this.card});


  // Function to set color of card
  void setColor() {
    switch (card[0]) {
      case 'R':
        color = redCard;
        break;
      case 'O':
        color = orangeCard;
        break;
      case 'Y':
        color = yellowCard;
        break;
      case 'G':
        color = greenCard;
        break;
      case 'B':
        color = blueCard;
        break;
      case 'I':
        color = indigoCard;
        break;
      case 'V':
        color = violetCard;
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    setColor();
    return Container(
      height: 54,
      width: 76,
      decoration:  BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: grey3A3A3AColor, width: 1.5),
      ),
      child: Center(
        // Add additional line to card for prettier look
        child: Container(
          height: 47,
          width: 69,
          decoration:  BoxDecoration(
            color: invisColor,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: Colors.white, width: 1.5),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Rotate card for get an illusion that it is flipped and it is another person's card
                Transform.rotate(
                  angle: -1.57,
                  child: Text(
                    card[1] == '0' ? '' : card[1],
                    style: otherCardNumStyle,
                  ),
                ),
                Padding(padding: const EdgeInsets.only(left: 14.4)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}