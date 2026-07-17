/// 富文本块类型
enum BlockType { heading, paragraph, image, quote, bulletList, exerciseCard, callout }

/// 富文本内容块
class ContentBlock {
  final BlockType type;
  final String? text;
  final String? imageUrl;
  final String? imageCaption;
  final String? exerciseId;
  final String? calloutType; // tip / warning / info

  const ContentBlock({
    required this.type,
    this.text,
    this.imageUrl,
    this.imageCaption,
    this.exerciseId,
    this.calloutType,
  });

  // 便捷构造器
  const ContentBlock.heading(String t) : this(type: BlockType.heading, text: t);
  const ContentBlock.paragraph(String t) : this(type: BlockType.paragraph, text: t);
  const ContentBlock.image(String url, [String? caption])
      : this(type: BlockType.image, imageUrl: url, imageCaption: caption);
  const ContentBlock.quote(String t) : this(type: BlockType.quote, text: t);
  const ContentBlock.bulletList(String items) : this(type: BlockType.bulletList, text: items);
  const ContentBlock.exerciseCard(String id) : this(type: BlockType.exerciseCard, exerciseId: id);
  const ContentBlock.callout(String t, String type) : this(type: BlockType.callout, text: t, calloutType: type);
}
