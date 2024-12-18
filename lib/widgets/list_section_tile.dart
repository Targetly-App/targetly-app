import 'package:flutter/material.dart';

class ListSectionTile extends StatefulWidget {
  final String? title;
  final Widget? leading;
  final String? subtitle;
  final TextOverflow? subtitleOverflow;
  final Widget? bottom;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;
  final Function()? onTap;

  const ListSectionTile(
      {super.key,
      this.title,
      this.subtitle,
      this.subtitleOverflow,
      this.bottom,
      this.leading,
      this.trailing,
      this.padding,
      this.onTap});

  @override
  _ListSectionTileState createState() => _ListSectionTileState();
}

class _ListSectionTileState extends State<ListSectionTile> {
  bool isSelected = false;

  @override
  void initState() {
    isSelected = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap != null
          ? () {
              setState(() {
                isSelected = !isSelected;
              });
              widget.onTap!();

              // wait 100 ms to reset the selection
              Future.delayed(const Duration(milliseconds: 100), () {
                setState(() {
                  isSelected = false;
                });
              });
            }
          : null,
      child: Container(
        padding: widget.padding ??
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color:
            isSelected ? const Color.fromARGB(72, 0, 0, 0) : Colors.transparent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (widget.leading != null)
              Padding(
                padding: const EdgeInsets.only(
                  right: 16,
                  top: 8,
                  bottom: 8,
                ),
                child: widget.leading!,
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.title != null && widget.title!.isNotEmpty)
                    Text(
                      widget.title!,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  if (widget.subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        widget.subtitle!,
                        overflow: widget.subtitleOverflow,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w300),
                      ),
                    ),
                  if (widget.bottom != null) widget.bottom!,
                ],
              ),
            ),
            if (widget.onTap != null && widget.trailing == null)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                ),
              )
            else if (widget.trailing != null)
              widget.trailing!,
          ],
        ),
      ),
    );
  }
}
