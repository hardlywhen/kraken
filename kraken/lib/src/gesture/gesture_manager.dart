/*
 * Copyright (C) 2019-present Alibaba Inc. All rights reserved.
 * Author: Kraken Team.
 */

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:kraken/dom.dart';
import 'package:kraken/gesture.dart';
import 'package:kraken/rendering.dart';
import 'package:kraken/src/gesture/pointer.dart' as gesture_pointer;

class GestureManager {

  static GestureManager? _instance;
  GestureManager._();

  factory GestureManager.instance() {
    if (_instance == null) {
      _instance = GestureManager._();

      _instance!._gestures[EVENT_CLICK] = TapGestureRecognizer();
      (_instance!._gestures[EVENT_CLICK] as TapGestureRecognizer).onTapDown = _instance!.onClick;

      _instance!._gestures[EVENT_DOUBLE_CLICK] = DoubleTapGestureRecognizer();
      (_instance!._gestures[EVENT_DOUBLE_CLICK] as DoubleTapGestureRecognizer).onDoubleTapDown = _instance!.onDoubleClick;

      _instance!._gestures[EVENT_SWIPE] = SwipeGestureRecognizer();
      (_instance!._gestures[EVENT_SWIPE] as SwipeGestureRecognizer).onSwipe = _instance!.onSwipe;

      _instance!._gestures[EVENT_PAN] = PanGestureRecognizer();
      (_instance!._gestures[EVENT_PAN] as PanGestureRecognizer).onStart = _instance!.onPanStart;
      (_instance!._gestures[EVENT_PAN] as PanGestureRecognizer).onUpdate = _instance!.onPanUpdate;
      (_instance!._gestures[EVENT_PAN] as PanGestureRecognizer).onEnd = _instance!.onPanEnd;

      _instance!._gestures[EVENT_LONG_PRESS] = LongPressGestureRecognizer();
      (_instance!._gestures[EVENT_LONG_PRESS] as LongPressGestureRecognizer).onLongPressEnd = _instance!.onLongPressEnd;

      _instance!._gestures[EVENT_SCALE] = ScaleGestureRecognizer();
      (_instance!._gestures[EVENT_SCALE] as ScaleGestureRecognizer).onStart = _instance!.onScaleStart;
      (_instance!._gestures[EVENT_SCALE] as ScaleGestureRecognizer).onUpdate = _instance!.onScaleUpdate;
      (_instance!._gestures[EVENT_SCALE] as ScaleGestureRecognizer).onEnd = _instance!.onScaleEnd;
    }
    return _instance!;
  }

  final Map<String, GestureRecognizer> _gestures = <String, GestureRecognizer>{};

  final List<EventTarget> _hitTestTargetList = [];
  // Collect the events in the hitTest list.
  final Map<String, bool> _hitTestEventMap = {};

  final Map<int, gesture_pointer.Pointer> _pointerIdToPointer = {};

  Element? _target;

  void addTargetToList(RenderBox target) {
    if (target is RenderPointerListenerMixin) {
      HandleGetEventTarget? getEventTarget = target.getEventTarget;
      if (getEventTarget != null) {
        _hitTestTargetList.add(getEventTarget());
      }
    }
  }

  void addPointer(PointerEvent event) {
    String touchType;

    if (event is PointerDownEvent) {
      // Reset the hitTest event map when start a new gesture.
      _hitTestEventMap.clear();

      _pointerIdToPointer[event.pointer] = gesture_pointer.Pointer(event);

      for (int i = 0; i < _hitTestTargetList.length; i++) {
        EventTarget eventTarget = _hitTestTargetList[i];
        eventTarget.getEventHandlers().keys.forEach((eventType) {
          _hitTestEventMap[eventType] = true;
        });
      }

      touchType = EVENT_TOUCH_START;

      // Add pointer to gestures then register the gesture recognizer to the arena.
      _gestures.forEach((key, gesture) {
        // Register the recognizer that needs to be monitored.
        if (_hitTestEventMap.containsKey(key)) {
          gesture.addPointer(event);
        }
      });

      // The target node triggered by the gesture is the bottom node of hitTest.
      // The scroll element needs to be judged by isScrollingContentBox to find the real element upwards.
      if (_hitTestTargetList.isNotEmpty) {
        for (int i = 0; i < _hitTestTargetList.length; i++) {
          EventTarget eventTarget = _hitTestTargetList[i];
          if (eventTarget is Element) {
            gesture_pointer.Pointer? pointer = _pointerIdToPointer[event.pointer];
            if (pointer != null) {
              pointer.target = eventTarget;
            }
            break;
          }
        }
      }

      _hitTestTargetList.clear();
    } else if (event is PointerMoveEvent) {
      touchType = EVENT_TOUCH_MOVE;
    } else if (event is PointerUpEvent) {
      touchType = EVENT_TOUCH_END;
    } else {
      touchType = EVENT_TOUCH_CANCEL;
    }

    gesture_pointer.Pointer? pointer = _pointerIdToPointer[event.pointer];
    if (pointer != null) {
      pointer.updateEvent(event);
    }

    // If the target node is not attached, the event will be ignored.
    if (_pointerIdToPointer[event.pointer] == null) return;

    // Only dispatch touch event that added.
    bool needDispatch = _hitTestEventMap.containsKey(touchType);
    if (needDispatch && pointer != null) {
      Function? handleTouchEvent = (pointer.target as Element).handleTouchEvent;
      handleTouchEvent(touchType, _pointerIdToPointer[event.pointer], _pointerIdToPointer.values.toList());
    }

    // End of the gesture.
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      // Multi pointer operations in the web will organize click and other gesture triggers.
      bool isSinglePointer = _pointerIdToPointer.length == 1;
      gesture_pointer.Pointer? pointer = _pointerIdToPointer[event.pointer];
      if (isSinglePointer && pointer != null) {
        _target = pointer.target;
      } else {
        _target = null;
      }

      _pointerIdToPointer.remove(event.pointer);
    }
  }

  void onDoubleClick(TapDownDetails details) {
    Function? handleMouseEvent = _target?.handleMouseEvent;
    if (handleMouseEvent != null) {
      handleMouseEvent(EVENT_DOUBLE_CLICK, localPosition: details.localPosition, globalPosition: details.globalPosition);
    }
  }

  void onClick(TapDownDetails details) {
    Function? handleMouseEvent = _target?.handleMouseEvent;
    if (handleMouseEvent != null) {
      handleMouseEvent(EVENT_CLICK, localPosition: details.localPosition, globalPosition: details.globalPosition);
    }
  }

  void onLongPressEnd(LongPressEndDetails details) {
    Function? handleMouseEvent = _target?.handleMouseEvent;
    if (handleMouseEvent != null) {
      handleMouseEvent(EVENT_LONG_PRESS, localPosition: details.localPosition, globalPosition: details.globalPosition);
    }
  }

  void onSwipe(SwipeDetails details) {
    Function? handleGestureEvent = _target?.handleGestureEvent;
    if (handleGestureEvent != null) {
      handleGestureEvent(EVENT_SWIPE, velocityX: details.velocity.pixelsPerSecond.dx, velocityY: details.velocity.pixelsPerSecond.dy);
    }
  }

  void onPanStart(DragStartDetails details) {
    Function? handleGestureEvent = _target?.handleGestureEvent;
    if (handleGestureEvent != null) {
      handleGestureEvent(EVENT_PAN, state: EVENT_STATE_START, deltaX: details.globalPosition.dx, deltaY: details.globalPosition.dy);
    }
  }

  void onPanUpdate(DragUpdateDetails details) {
    Function? handleGestureEvent = _target?.handleGestureEvent;
    if (handleGestureEvent != null) {
      handleGestureEvent(EVENT_PAN, state: EVENT_STATE_UPDATE, deltaX: details.globalPosition.dx, deltaY: details.globalPosition.dy);
    }
  }

  void onPanEnd(DragEndDetails details) {
    Function? handleGestureEvent = _target?.handleGestureEvent;
    if (handleGestureEvent != null) {
      handleGestureEvent(EVENT_PAN, state: EVENT_STATE_END, velocityX: details.velocity.pixelsPerSecond.dx, velocityY: details.velocity.pixelsPerSecond.dy);
    }
  }

  void onScaleStart(ScaleStartDetails details) {
    Function? handleGestureEvent = _target?.handleGestureEvent;
    if (handleGestureEvent != null) {
      handleGestureEvent(EVENT_SCALE, state: EVENT_STATE_START);
    }
  }

  void onScaleUpdate(ScaleUpdateDetails details) {
    Function? handleGestureEvent = _target?.handleGestureEvent;
    if (handleGestureEvent != null) {
      handleGestureEvent(EVENT_SCALE, state: EVENT_STATE_UPDATE, rotation: details.rotation, scale: details.scale);
    }
  }

  void onScaleEnd(ScaleEndDetails details) {
    Function? handleGestureEvent = _target?.handleGestureEvent;
    if (handleGestureEvent != null) {
      handleGestureEvent(GestureEvent, state: EVENT_STATE_END);
    }
  }
}
