import 'package:flutter/material.dart';

import '../data/styles.dart';

class CentralCardWidget extends StatelessWidget {
  final String card;
  Color color = invisColor;

  CentralCardWidget({super.key, required this.card});

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
      height: 84,
      width: 60,
      decoration:  BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: grey3A3A3AColor, width: 1.5),
      ),
      child: Center(
        child: Container(
          height: 76,
          width: 52,
          decoration:  BoxDecoration(
            color: invisColor,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: Colors.white, width: 1.5),
          ),
          child: Center(
            child: Text(
              card[1] == '0' ? '' : card[1],
              style: cardNumStyle,
            ),
          ),
        ),
      ),
    );
  }
}

class HandCardWidget extends StatelessWidget {
  final String card;
  Color color = invisColor;

  HandCardWidget({super.key, required this.card});

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
      height: 106,
      width: 71,
      decoration:  BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: grey3A3A3AColor, width: 1.5),
      ),
      child: Center(
        child: Container(
          height: 98,
          width: 63,
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

class LeftCardWidget extends StatelessWidget {
  final String card;
  Color color = invisColor;

  LeftCardWidget({super.key, required this.card});

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
      height: 60,
      width: 84,
      decoration:  BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: grey3A3A3AColor, width: 1.5),
      ),
      child: Center(
        child: Container(
          height: 52,
          width: 76,
          decoration:  BoxDecoration(
            color: invisColor,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: Colors.white, width: 1.5),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(padding: const EdgeInsets.only(left: 16)),
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


class RightCardWidget extends StatelessWidget {
  final String card;
  Color color = invisColor;

  RightCardWidget({super.key, required this.card});

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
      height: 60,
      width: 84,
      decoration:  BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: grey3A3A3AColor, width: 1.5),
      ),
      child: Center(
        child: Container(
          height: 52,
          width: 76,
          decoration:  BoxDecoration(
            color: invisColor,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: Colors.white, width: 1.5),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.rotate(
                  angle: -1.57,
                  child: Text(
                    card[1] == '0' ? '' : card[1],
                    style: otherCardNumStyle,
                  ),
                ),
                Padding(padding: const EdgeInsets.only(left: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}