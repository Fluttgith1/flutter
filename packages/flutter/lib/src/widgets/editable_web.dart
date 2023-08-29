// ignore_for_file: public_member_api_docs
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui' as ui; // change to ui_web when you update
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'dart:math' as math;

class EditableWeb extends StatefulWidget {
  const EditableWeb({
    super.key,
    required this.inlineSpan,
    required this.value,
    required this.startHandleLayerLink,
    required this.endHandleLayerLink,
    required this.cursorColor,
    this.backgroundCursorColor,
    required this.showCursor,
    required this.forceLine,
    this.textHeightBehavior,
    required this.textWidthBasis,
    required this.hasFocus,
    required this.maxLines,
    this.minLines,
    required this.expands,
    this.strutStyle,
    this.selectionColor,
    required this.textScaler,
    required this.textAlign,
    required this.textDirection,
    this.locale,
    required this.obscuringCharacter,
    required this.offset,
    this.rendererIgnoresPointer = false,
    required this.cursorWidth,
    this.cursorHeight,
    this.cursorRadius,
    required this.cursorOffset,
    required this.paintCursorAboveText,
    this.selectionHeightStyle = ui.BoxHeightStyle.tight,
    this.selectionWidthStyle = ui.BoxWidthStyle.tight,
    required this.textSelectionDelegate,
    required this.devicePixelRatio,
    this.promptRectRange,
    this.promptRectColor,
    required this.clipBehavior,
    required this.requestKeyboard,
    required this.clientId,
    required this.performAction,
    required this.textInputConfiguration, // contains a bunch of things like obscureText, readOnly, autofillHints, etc.
  });

  final InlineSpan inlineSpan;
  final TextEditingValue value;
  final Color cursorColor;
  final LayerLink startHandleLayerLink;
  final LayerLink endHandleLayerLink;
  final Color? backgroundCursorColor;
  final ValueNotifier<bool> showCursor;
  final bool forceLine;
  final bool hasFocus;
  final int? maxLines;
  final int? minLines;
  final bool expands;
  final StrutStyle? strutStyle;
  final Color? selectionColor;
  final TextScaler textScaler;
  final TextAlign textAlign;
  final TextDirection textDirection;
  final Locale? locale;
  final String obscuringCharacter;
  final TextHeightBehavior? textHeightBehavior;
  final TextWidthBasis textWidthBasis;
  final ViewportOffset offset;
  final bool rendererIgnoresPointer;
  final double cursorWidth;
  final double? cursorHeight;
  final Radius? cursorRadius;
  final Offset cursorOffset;
  final bool paintCursorAboveText;
  final ui.BoxHeightStyle selectionHeightStyle;
  final ui.BoxWidthStyle selectionWidthStyle;
  final TextSelectionDelegate textSelectionDelegate;
  final double devicePixelRatio;
  final TextRange? promptRectRange;
  final Color? promptRectColor;
  final Clip clipBehavior;
  final void Function() requestKeyboard;
  final int clientId;
  final void Function(TextInputAction) performAction;
  final TextInputConfiguration textInputConfiguration;

  @override
  State<EditableWeb> createState() => _EditableWebState();
}

class _EditableWebState extends State<EditableWeb> {
  late html.HtmlElement _inputEl;
  html.InputElement? _inputElement;
  html.TextAreaElement? _textAreaElement;
  double sizedBoxHeight = 24;
  late final int _maxLines;
  TextEditingValue? lastEditingState;

  @override
  void initState() {
    super.initState();
    _maxLines = widget.maxLines ?? 1;
  }

  @override
  void dispose() {
    print('EditableWeb.dispose()');
    WebTextInputControl.instance.deregisterInstance(widget.clientId);

    super.dispose();
  }

  String getElementValue(html.HtmlElement inputEl) {
    return (inputEl as html.InputElement).value!;
  }

  void setElementValue(String value) {
    (_inputEl as html.InputElement).value = value;
  }

  String colorToCss(Color color) {
    // hard coding opacity to 1 for now because EditableText passes cursorColor with 0 opacity.
    return 'rgba(${color.red}, ${color.green}, ${color.blue}, ${color.opacity == 0 ? 1 : color.opacity})';
  }

  String textStyleToCss(TextStyle style) {
    List<String> cssProperties = [];

    if (style.color != null) {
      cssProperties.add('color: ${colorToCss(style.color!)}');
    }

    if (style.fontSize != null) {
      cssProperties.add('font-size: ${style.fontSize}px');
    }

    if (style.fontWeight != null) {
      cssProperties.add('font-weight: ${style.fontWeight!.value}');
    }

    if (style.fontStyle != null) {
      cssProperties.add(
          'font-style: ${style.fontStyle == FontStyle.italic ? 'italic' : 'normal'}');
    }

    if (style.fontFamily != null) {
      cssProperties.add('font-family: "${style.fontFamily}"');
    }

    if (style.letterSpacing != null) {
      cssProperties.add('letter-spacing: ${style.letterSpacing}px');
    }

    if (style.wordSpacing != null) {
      cssProperties.add('word-spacing: ${style.wordSpacing}');
    }

    if (style.decoration != null) {
      List<String> textDecorations = [];
      TextDecoration decoration = style.decoration!;

      if (decoration == TextDecoration.none) {
        textDecorations.add('none');
      } else {
        if (decoration.contains(TextDecoration.underline)) {
          textDecorations.add('underline');
        }

        if (decoration.contains(TextDecoration.underline)) {
          textDecorations.add('underline');
        }

        if (decoration.contains(TextDecoration.underline)) {
          textDecorations.add('underline');
        }
      }

      cssProperties.add('text-decoration: ${textDecorations.join(' ')}');
    }

    return cssProperties.join('; ');
  }

  /// NOTE: Taken from engine
  /// TODO: make more functional, set autocap attr outside of function using return val
  /// Sets `autocapitalize` attribute on input elements.
  ///
  /// This attribute is only available for mobile browsers.
  ///
  /// Note that in mobile browsers the onscreen keyboards provide sentence
  /// level capitalization as default as apposed to no capitalization on desktop
  /// browser.
  ///
  /// See: https://developers.google.com/web/updates/2015/04/autocapitalize
  /// https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes/autocapitalize
  void setAutocapitalizeAttribute(html.HtmlElement inputEl) {
    String autocapitalize = '';
    switch (widget.textInputConfiguration.textCapitalization) {
      case TextCapitalization.words:
        // TODO(mdebbar): There is a bug for `words` level capitalization in IOS now.
        // For now go back to default. Remove the check after bug is resolved.
        // https://bugs.webkit.org/show_bug.cgi?id=148504
        // TODO add browser engines
        // if (browserEngine == BrowserEngine.webkit) {
        //   autocapitalize = 'sentences';
        // } else {
        //   autocapitalize = 'words';
        // }
        autocapitalize = 'words';
      case TextCapitalization.characters:
        autocapitalize = 'characters';
      case TextCapitalization.sentences:
        autocapitalize = 'sentences';
      case TextCapitalization.none:
      default:
        autocapitalize = 'off';
        break;
    }
    (inputEl as html.InputElement).autocapitalize = autocapitalize;
  }

  /// NOTE: Taken from engine.
  /// Converts [align] to its corresponding CSS value.
  ///
  /// This value is used as the "text-align" CSS property, e.g.:
  ///
  /// ```css
  /// text-align: right;
  /// ```
  String textAlignToCssValue(
      ui.TextAlign? align, ui.TextDirection textDirection) {
    switch (align) {
      case ui.TextAlign.left:
        return 'left';
      case ui.TextAlign.right:
        return 'right';
      case ui.TextAlign.center:
        return 'center';
      case ui.TextAlign.justify:
        return 'justify';
      case ui.TextAlign.end:
        switch (textDirection) {
          case ui.TextDirection.ltr:
            return 'end';
          case ui.TextDirection.rtl:
            return 'left';
        }
      case ui.TextAlign.start:
        switch (textDirection) {
          case ui.TextDirection.ltr:
            return ''; // it's the default
          case ui.TextDirection.rtl:
            return 'right';
        }
      case null:
        // If align is not specified return default.
        return '';
    }
  }

  /// Takes a font size read from the style property (e.g. '16px) and scales it
  /// by some factor. Returns the scaled font size in a CSS friendly format.
  /// TODO
  // String scaleFontSize(String fontSize, double textScaleFactor) {
  //   assert(fontSize.endsWith('px'));
  //   final String strippedFontSize = fontSize.replaceAll('px', '');
  //   final double parsedFontSize = double.parse(strippedFontSize);
  //   final int scaledFontSize = (parsedFontSize * textScaleFactor).round();

  //   return '${scaledFontSize}px';
  // }

  Map<String, String> getKeyboardTypeAttributes(TextInputType inputType) {
    final bool isDecimal = inputType.decimal ?? false; // appropriate default?

    switch (inputType) {
      case TextInputType.number:
        return {
          'type': 'number',
          'inputmode': isDecimal ? 'decimal' : 'numeric'
        };
      case TextInputType.phone:
        return {'type': 'tel', 'inputmode': 'tel'};
      case TextInputType.emailAddress:
        return {'type': 'email', 'inputmode': 'email'};
      case TextInputType.url:
        return {'type': 'url', 'inputmode': 'url'};
      case TextInputType.none:
        return {'type': 'text', 'inputmode': 'none'};
      case TextInputType.text:
        return {'type': 'text', 'inputmode': 'text'};
      default:
        return {'type': 'text', 'inputmode': 'text'};
    }
  }

  String? getEnterKeyHint(TextInputAction inputAction) {
    switch (inputAction) {
      case TextInputAction.continueAction:
      case TextInputAction.next:
        return 'next';
      case TextInputAction.previous:
        return 'previous';
      case TextInputAction.done:
        return 'done';
      case TextInputAction.go:
        return 'go';
      case TextInputAction.newline:
        return 'enter';
      case TextInputAction.search:
        return 'search';
      case TextInputAction.send:
        return 'send';
      case TextInputAction.emergencyCall:
      case TextInputAction.join:
      case TextInputAction.none:
      case TextInputAction.route:
      case TextInputAction.unspecified:
      default:
        return null;
    }
  }

  String _getAutocompleteAttribute(String autofillHint) {
    switch (autofillHint) {
      case AutofillHints.birthday:
        return 'bday';
      case AutofillHints.birthdayDay:
        return 'bday-day';
      case AutofillHints.birthdayMonth:
        return 'bday-month';
      case AutofillHints.birthdayYear:
        return 'bday-year';
      case AutofillHints.countryCode:
        return 'country';
      case AutofillHints.countryName:
        return 'country-name';
      case AutofillHints.creditCardExpirationDate:
        return 'cc-exp';
      case AutofillHints.creditCardExpirationMonth:
        return 'cc-exp-month';
      case AutofillHints.creditCardExpirationYear:
        return 'cc-exp-year';
      case AutofillHints.creditCardFamilyName:
        return 'cc-family-name';
      case AutofillHints.creditCardGivenName:
        return 'cc-given-name';
      case AutofillHints.creditCardMiddleName:
        return 'cc-additional-name';
      case AutofillHints.creditCardName:
        return 'cc-name';
      case AutofillHints.creditCardNumber:
        return 'cc-number';
      case AutofillHints.creditCardSecurityCode:
        return 'cc-csc';
      case AutofillHints.creditCardType:
        return 'cc-type';
      case AutofillHints.email:
        return 'email';
      case AutofillHints.familyName:
        return 'family-name';
      case AutofillHints.fullStreetAddress:
        return 'street-address';
      case AutofillHints.gender:
        return 'sex';
      case AutofillHints.givenName:
        return 'given-name';
      case AutofillHints.impp:
        return 'impp';
      case AutofillHints.jobTitle:
        return 'organization-title';
      case AutofillHints.middleName:
        return 'middleName';
      case AutofillHints.name:
        return 'name';
      case AutofillHints.namePrefix:
        return 'honorific-prefix';
      case AutofillHints.nameSuffix:
        return 'honorific-suffix';
      case AutofillHints.newPassword:
        return 'new-password';
      case AutofillHints.nickname:
        return 'nickname';
      case AutofillHints.oneTimeCode:
        return 'one-time-code';
      case AutofillHints.organizationName:
        return 'organization';
      case AutofillHints.password:
        return 'current-password';
      case AutofillHints.photo:
        return 'photo';
      case AutofillHints.postalCode:
        return 'postal-code';
      case AutofillHints.streetAddressLevel1:
        return 'address-level1';
      case AutofillHints.streetAddressLevel2:
        return 'address-level2';
      case AutofillHints.streetAddressLevel3:
        return 'address-level3';
      case AutofillHints.streetAddressLevel4:
        return 'address-level4';
      case AutofillHints.streetAddressLine1:
        return 'address-line1';
      case AutofillHints.streetAddressLine2:
        return 'address-line2';
      case AutofillHints.streetAddressLine3:
        return 'address-line3';
      case AutofillHints.telephoneNumber:
        return 'tel';
      case AutofillHints.telephoneNumberAreaCode:
        return 'tel-area-code';
      case AutofillHints.telephoneNumberCountryCode:
        return 'tel-country-code';
      case AutofillHints.telephoneNumberExtension:
        return 'tel-extension';
      case AutofillHints.telephoneNumberLocal:
        return 'tel-local';
      case AutofillHints.telephoneNumberLocalPrefix:
        return 'tel-local-prefix';
      case AutofillHints.telephoneNumberLocalSuffix:
        return 'tel-local-suffix';
      case AutofillHints.telephoneNumberNational:
        return 'tel-national';
      case AutofillHints.transactionAmount:
        return 'transaction-amount';
      case AutofillHints.transactionCurrency:
        return 'transaction-currency';
      case AutofillHints.url:
        return 'url';
      case AutofillHints.username:
        return 'username';
      default:
        return autofillHint;
    }
  }

  void setElementStyles(html.HtmlElement inputEl) {
    // style based on TextStyle
    if (widget.inlineSpan.style != null) {
      inputEl.style.cssText = textStyleToCss(widget.inlineSpan.style!);
    }

    // reset input styles
    inputEl.style
      ..width = '100%'
      ..height = '100%'
      ..setProperty(
          'caret-color',
          widget.showCursor.value
              ? colorToCss(widget.cursorColor)
              : 'transparent')
      ..outline = 'none'
      ..border = 'none'
      ..background = 'transparent'
      ..padding = '0'
      ..textAlign = textAlignToCssValue(widget.textAlign, widget.textDirection)
      // ..pointerEvents = widget.rendererIgnoresPointer ? 'none' : 'auto' // Can't use this, material3 text field sets this to none
      ..direction = widget.textDirection.name
      ..lineHeight = '1.5'; // can this be modified by a property?

    // debug
    if (widget.textInputConfiguration.obscureText) {
      inputEl.style.border = '1px solid red'; // debug
    }

    if (widget.selectionColor != null) {
      /*
        Needs the following code in engine
          sheet.insertRule('''
            $cssSelectorPrefix flt-glass-pane {
              --selection-background: #000000; 
            }
          ''', sheet.cssRules.length);

          sheet.insertRule('''
            $cssSelectorPrefix .customInputSelection::selection {
              background-color: var(--selection-background);
            }
          ''', sheet.cssRules.length);
      */
      // There is no easy way to modify pseudoclasses via js. We are accomplishing this
      // here via modifying a css var that is responsible for this ::selection style
      html.document.querySelector('flt-glass-pane')!.style.setProperty(
          '--selection-background', colorToCss(widget.selectionColor!));

      // To ensure we're only modifying selection on this specific input, we attach a custom class
      // instead of adding a blanket rule for all inputs.
      inputEl.classes.add('customInputSelection');
    }
  }

  // TODO: Handle composition and delta model?
  void handleChange(html.Event event) {
    final html.InputElement element = _inputEl as html.InputElement;
    final String text = element.value!;
    final TextSelection selection = TextSelection(
        baseOffset: element.selectionStart ?? 0,
        extentOffset: element.selectionEnd ?? 0);

    final TextEditingValue newEditingState =
        TextEditingValue(text: text, selection: selection);

    if (newEditingState != lastEditingState) {
      lastEditingState = newEditingState;
      updateEditingState(newEditingState);
    }
  }

  void setElementListeners(html.HtmlElement inputEl) {
    // listen for events
    inputEl.onInput.listen((e) {
      handleChange(e);
    });

    inputEl.onFocus.listen((e) {
      widget.requestKeyboard();

      if (widget.selectionColor != null) {
        // Since we're relying on a CSS variable to handle selection background, we
        // run into an issue when there are multiple inputs with multiple selection background
        // values. In that case, the variable is always set to whatever the last rendered input's selection
        // background value was set to.  To fix this, we update that CSS variable to the currently focused
        // element's selection color value.
        inputEl.classes.add('customInputSelection');
        html.document.querySelector('flt-glass-pane')!.style.setProperty(
            '--selection-background', colorToCss(widget.selectionColor!));
      }
    });

    inputEl.onKeyDown.listen((html.KeyboardEvent event) {
      maybeSendAction(event);
    });

    // Prevent default for mouse events to prevent selection interference/flickering.
    // We want to let the framework handle these pointerevents.
    inputEl.onMouseDown.listen((html.MouseEvent event) {
      event.preventDefault();
    });

    inputEl.onMouseUp.listen((html.MouseEvent event) {
      event.preventDefault();
    });

    inputEl.onMouseMove.listen((html.MouseEvent event) {
      event.preventDefault();
    });
  }

  void setGeneralAttributes(html.HtmlElement inputEl) {
    // calculate box size based on specified lines
    // TODO: can we make this better?
    sizedBoxHeight *= _maxLines;

    setAutocapitalizeAttribute(inputEl);

    inputEl.setAttribute(
        'autocorrect', widget.textInputConfiguration.autocorrect ? 'on' : 'off');
    

    final String? enterKeyHint = getEnterKeyHint(widget.textInputConfiguration.inputAction);

    if (enterKeyHint != null) {
      inputEl.setAttribute('enterkeyhint', enterKeyHint);
    }
  }

  void setInputElementAttributes(html.InputElement inputEl) {
    // set attributes
    inputEl.readOnly = widget.textInputConfiguration.readOnly;

    if (widget.textInputConfiguration.obscureText) {
      inputEl.type = 'password';
    } else {
      final Map<String, String> attributes =
          getKeyboardTypeAttributes(widget.textInputConfiguration.inputType);
      inputEl.type = attributes['type'];
      inputEl.inputMode = attributes['inputmode'];
    }

    if (widget.textInputConfiguration.autofillConfiguration.autofillHints.isNotEmpty) {
      // browsers can only use one autocomplete attribute
      final String autocomplete =
          _getAutocompleteAttribute(widget.textInputConfiguration.autofillConfiguration.autofillHints.first);
      inputEl.id = autocomplete;
      inputEl.name = autocomplete;
      inputEl.autocomplete = autocomplete;
    }

    _inputElement = inputEl;
  }

  void setTextAreaElementAttributes(html.TextAreaElement textAreaEl) {
    textAreaEl.rows = _maxLines;
    textAreaEl.readOnly = widget.textInputConfiguration.readOnly;
    _textAreaElement = textAreaEl;
  }

  void initializePlatformView(html.HtmlElement inputEl) {
    _maxLines > 1
        ? setTextAreaElementAttributes(inputEl as html.TextAreaElement)
        : setInputElementAttributes(inputEl as html.InputElement);
    setElementStyles(inputEl);
    setElementListeners(inputEl);
    setGeneralAttributes(inputEl);

    _inputEl = inputEl;

    // register instance via clientId.
    WebTextInputControl.instance.registerInstance(widget.clientId, this);
  }

  // --------------
  // Incoming methods
  /* Incoming methods (back to framework)
    - registered using MethodChannel.setMethodCallHandler
    - TextInputClient.updateEditingState -> send new editing state
    -- right now, this calls _updateEditingValue (on TextInput instance), which calls
    -- updateEditingValue (on the TextInputClient, which is EditableText). 
    - TextInputClient.updateEditingStateWithTag - ?
    - TextInputClient.performAction -> 
    - TextInputClient.requestExistingInputState
    - TextInputClient.onConnectionClosed
  */
  void updateEditingState(TextEditingValue value) {
    TextInput.updateEditingValue(value);
  }

  void updateEditingStateWithTag() {
    // autofill stuff?
  }

  void performAction(TextInputAction action) {
    widget.performAction(action);
  }

  void requestExistingInputState() {
    // no-op
  }

  void onConnectionClosed() {
    // no-op?
  }

  void maybeSendAction(html.KeyboardEvent event) {
    if (event.keyCode == html.KeyCode.ENTER) {
      performAction(widget.textInputConfiguration.inputAction);

      // Prevent the browser from inserting a new line when it's not a multiline input.
      // note: taken from engine. Do we still need?
      if (widget.textInputConfiguration.inputType != TextInputType.multiline) {
        event.preventDefault();
      }
    }
  }

  @override
  void didUpdateWidget(EditableWeb oldWidget) {
    super.didUpdateWidget(oldWidget);

    // we do this because widget can sometimes selectionColor can be passed
    // as conditionally null depending on some state that's determined in a layer
    // above (e.g. `hasFocus`), so we need to keep track of the selectionColor
    // and set it when appropriate.
    if (widget.selectionColor != oldWidget.selectionColor) {
      if (widget.selectionColor != null) {
        html.document.querySelector('flt-glass-pane')!.style.setProperty(
            '--selection-background', colorToCss(widget.selectionColor!));
        _inputEl.classes.add('customInputSelection');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('textInputConfiguration.autofillConfiguration.autofillHints: ${widget.textInputConfiguration.autofillConfiguration.autofillHints}');
    return SizedBox(
      height: sizedBoxHeight,
      child: HtmlElementView.fromTagName(
        tagName: _maxLines > 1 ? 'textarea' : 'input',
        onElementCreated: (Object element) {
          initializePlatformView(element as html.HtmlElement);
        },
      ),
    );
  }
}

class WebTextInputControl with TextInputControl {
  WebTextInputControl._();

  /// The shared instance of [WebTextInputControl].
  static final WebTextInputControl instance = WebTextInputControl._();

  Map<int, _EditableWebState> editableWebMap = <int, _EditableWebState>{};
  html.HtmlElement? _currentInputElement;
  _EditableWebState? _currentEditableWebInstance;

  // We should only ever have one selectionchange event listener on the document.
  // We should add the listener on `attach()` and remove it on `detach()` to make
  // sure that the listener is only ever added for the currently "active" input element.
  late void Function(html.Event) handleChangeRef;

  // html.HtmlElement? get _inputEl => TextInput._instance._inputEl;

  /// Register an input element. We use an EditableText clientId because we need
  /// an id that can be referenced from a TextInputClient (due to attach's function
  /// signature).
  void registerInstance(int clientId, _EditableWebState instance) {
    print('WebTextInputControl.register()');
    editableWebMap[clientId] = instance;
  }

  /// De-register an input element.
  void deregisterInstance(int clientId) {
    print('WebTextInputControl.deregister()');
    editableWebMap.remove(clientId);
  }

  // TODO: We should set the configuration here.
  @override
  void attach(TextInputClient client, TextInputConfiguration configuration) {
    // set currentInputElement by grabbing it from the map. This is why we have to register
    // the id of the TextInputClient (editabletext) above, because we need that id in attach.
    print('WebTextInputControl.attach()');
    _currentEditableWebInstance = editableWebMap[client.clientId];
    _currentInputElement = _currentEditableWebInstance!._inputEl;

    // Add selectionchange listener. attach() seems like the best place to put this
    // as this is the agreed upon place with the framework where an input gets activated.
    // Other options: Listen to focus and blur changes in the EditableWeb widget and keep it there.
    // Or we can keep logic within a method of our EditableWeb instance and just call it here.
    handleChangeRef = _currentEditableWebInstance!.handleChange;
    html.document.addEventListener('selectionchange', handleChangeRef);
  }

  @override
  void detach(TextInputClient client) {
    print('WebTextInputControl.detach()');
    // Blur here since order goes detach -> hide.
    (_currentInputElement! as html.InputElement).blur();

    // Remove selectionchange listener.
    html.document.removeEventListener('selectionchange', handleChangeRef);

    // Reset current elements.
    _currentEditableWebInstance = null;
    _currentInputElement = null;
  }

  // Currently, we directly set the visual appearance of our textfield by props
  // directly passed into EditableWeb. Should we use this instead?
  @override
  void updateConfig(TextInputConfiguration configuration) {}

  @override
  void setEditingState(TextEditingValue value) {
    print('WebTextInputControl.setEditingState()');
    final html.InputElement element =
        _currentInputElement! as html.InputElement;
    final int minOffset =
        math.min(value.selection.baseOffset, value.selection.extentOffset);
    final int maxOffset =
        math.max(value.selection.baseOffset, value.selection.extentOffset);
    final TextAffinity affinity = value.selection.affinity;
    String direction;

    // do we need this?
    switch (affinity) {
      case TextAffinity.upstream:
        direction = 'backward';
      case TextAffinity.downstream:
        direction = 'forward';
    }

    final TextEditingValue lastEditingState = TextEditingValue(
      text: value.text,
      selection: TextSelection(
        baseOffset: value.selection.baseOffset,
        extentOffset: value.selection.extentOffset,
      ),
    );

    element.value = value.text;
    element.setSelectionRange(minOffset, maxOffset);

    _currentEditableWebInstance!.lastEditingState = lastEditingState;
  }

  @override
  void show() {
    (_currentInputElement! as html.InputElement).focus();
  }

  @override
  void hide() {
    // We need to check if this is null because detach is called before hide.
    // In detach, we blur and reset the _currentInputElement.
    // This blur call is for instances where we blur to hide keyboard without
    // detaching the connection (if such a circumstance exists).
    if (_currentInputElement != null) {
      (_currentInputElement! as html.InputElement).blur();
    }
  }

  @override
  void setEditableSizeAndTransform(Size editableBoxSize, Matrix4 transform) {}

  @override
  void setComposingRect(Rect rect) {}

  @override
  void setCaretRect(Rect rect) {}

  @override
  void setSelectionRects(List<SelectionRect> selectionRects) {}

  // Currently, we directly set the style of our textfield by props
  // directly passed into EditableWeb. Should we use this instead?
  @override
  void setStyle({
    required String? fontFamily,
    required double? fontSize,
    required FontWeight? fontWeight,
    required TextDirection textDirection,
    required TextAlign textAlign,
  }) {}

  // no-op
  @override
  void requestAutofill() {}

  @override
  void finishAutofillContext({bool shouldSave = true}) {}
}
