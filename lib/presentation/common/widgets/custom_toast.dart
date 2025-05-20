import 'package:flutter/material.dart';

enum ToastType { success, error, info, warning }

class CustomToast {
  static void show({
    required BuildContext context,
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onDismiss,
  }) {
    // Dismiss any existing toast
    _dismissCurrentToast(context);
    
    // Get the overlay state
    final overlay = Overlay.of(context);
    
    // Create a variable to hold the entry
    late OverlayEntry entry;
    
    // Now define the entry
    entry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        type: type,
        onDismiss: () {
          entry.remove();
          if (onDismiss != null) onDismiss();
        },
      ),
    );
    
    // Insert the overlay entry
    overlay.insert(entry);
    
    // Auto dismiss after duration
    Future.delayed(duration, () {
      if (entry.mounted) {
        entry.remove();
        if (onDismiss != null) onDismiss();
      }
    });
  }
  
  static void _dismissCurrentToast(BuildContext context) {
    // This would be implemented if you want to track and dismiss existing toasts
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final ToastType type;
  final VoidCallback onDismiss;
  
  const _ToastWidget({
    required this.message,
    required this.type,
    required this.onDismiss,
  });
  
  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Material(
        color: Colors.transparent,
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
            child: FadeTransition(
              opacity: _animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -1),
                  end: Offset.zero,
                ).animate(_animation),
                child: _buildToastContent(),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildToastContent() {
    Color backgroundColor;
    Color textColor = Colors.white;
    IconData iconData;
    
    switch (widget.type) {
      case ToastType.success:
        backgroundColor = Colors.green;
        iconData = Icons.check_circle;
        break;
      case ToastType.error:
        backgroundColor = Colors.red;
        iconData = Icons.error;
        break;
      case ToastType.warning:
        backgroundColor = Colors.orange;
        iconData = Icons.warning;
        break;
      case ToastType.info:
      default:
        backgroundColor = Colors.blue;
        iconData = Icons.info;
        break;
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(iconData, color: textColor),
          const SizedBox(width: 12.0),
          Expanded(
            child: Text(
              widget.message,
              style: TextStyle(color: textColor, fontSize: 16.0),
            ),
          ),
          GestureDetector(
            onTap: widget.onDismiss,
            child: Icon(Icons.close, color: textColor),
          ),
        ],
      ),
    );
  }
}
