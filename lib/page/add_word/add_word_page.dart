import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_abc/commons/enums.dart';

import '../../commons/app_colors.dart';
import '../../repository/vocabulary_repository.dart';
import 'add_word_cubit.dart';

class AddWordPage extends StatefulWidget {
  const AddWordPage({super.key});

  @override
  State<AddWordPage> createState() => _AddWordPageState();
}

class _AddWordPageState extends State<AddWordPage>
    with SingleTickerProviderStateMixin {
  late final AddWordCubit _cubit;
  late final AnimationController _cardController;
  late final Animation<double> _cardFadeAnimation;
  late final Animation<Offset> _cardSlideAnimation;

  final _vocabularyController = TextEditingController();
  final _furiganaController = TextEditingController();
  final _meaningController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cubit = AddWordCubit(context.read<VocabularyRepository>());

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _cardFadeAnimation = CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOut,
    );

    _cardSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _cubit.close();
    _cardController.dispose();
    _vocabularyController.dispose();
    _furiganaController.dispose();
    _meaningController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F4F8),
        appBar: _buildAppBar(),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPreviewCard(),
              const SizedBox(height: 24),
              _buildForm(),
              const SizedBox(height: 32),
              _buildButtonSubmit(),
            ],
          ),
        ),
      ),
    );
  }


  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFF2F4F8),
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.black87, size: 20),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: const Text(
        'Thêm mới',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
          letterSpacing: 0.3,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.bookmark_border_rounded,
              color: Color(0xFF6B7FD4), size: 22),
          onPressed: () {},
        ),
      ],
    );
  }


  Widget _buildPreviewCard() {
    return BlocBuilder<AddWordCubit, AddWordState>(
      builder: (context, state) {
        return SlideTransition(
          position: _cardSlideAnimation,
          child: FadeTransition(
            opacity: _cardFadeAnimation,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF7B6FD4), Color(0xFF5B8DEF)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6B7FD4).withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Column(
                children: [
                  Text(
                    'Thẻ từ vựng',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    state.vocabulary.isNotEmpty ? state.vocabulary : 'Từ vựng',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    state.furigana.isNotEmpty ? state.furigana : 'Phát âm',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 16,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Divider(
                        color: Colors.white.withOpacity(0.25), thickness: 1),
                  ),
                  Text(
                    state.meaning.isNotEmpty ? state.meaning : 'Nghĩa',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormField(
          label: 'Từ vựng',
          hint: 'Nhập từ vựng',
          controller: _vocabularyController,
          onChanged: _cubit.onVocabularyChanged,
          accentColor: const Color(0xFF6B7FD4),
        ),
        const SizedBox(height: 16),
        _buildFormField(
          label: 'Phát âm',
          hint: 'Nhập cách phát âm',
          controller: _furiganaController,
          onChanged: _cubit.onFuriganaChanged,
          accentColor: const Color(0xFF5B8DEF),
        ),
        const SizedBox(height: 16),
        _buildFormField(
          label: 'Nghĩa',
          hint: 'Nhập nghĩa từ',
          controller: _meaningController,
          onChanged: _cubit.onMeaningChanged,
          accentColor: const Color(0xFFF4A261),
          minLines: 2,
        ),

        /// Tag từ
        // Row(
        //   mainAxisAlignment: MainAxisAlignment.center,
        //   children: [
        //     _buildTag(
        //       state.wordType.isNotEmpty
        //           ? state.wordType
        //           : '動詞 (Verb)',
        //     ),
        //     const SizedBox(width: 8),
        //     _buildTag(
        //       state.jlptLevel.isNotEmpty
        //           ? state.jlptLevel
        //           : 'JLPT N5',
        //       isOutlined: true,
        //     ),
        //   ],
        // ),
        // const SizedBox(height: 16),
        /// action
        // Row(
        //   mainAxisAlignment: MainAxisAlignment.center,
        //   children: [
        //     _buildCardAction(Icons.volume_up_rounded, 'Listen'),
        //     const SizedBox(width: 28),
        //     _buildCardAction(Icons.flip_rounded, 'Flip'),
        //     const SizedBox(width: 28),
        //     _buildCardAction(Icons.share_rounded, 'Share'),
        //   ],
        // ),

      ],
    );
  }

  Widget _buildFormField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    required Color accentColor,
    int minLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 16,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            minLines: minLines,
            maxLines: minLines == 1 ? 1 : null,
            style: const TextStyle(fontSize: 15, color: Colors.black87),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: accentColor, width: 1.5),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTag(String label, {bool isOutlined = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:
        isOutlined ? Colors.transparent : Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: isOutlined
            ? Border.all(color: Colors.white.withOpacity(0.5), width: 1)
            : null,
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCardAction(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.55), size: 20),
        const SizedBox(height: 2),
        Text(
          label,
          style:
          TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildButtonSubmit (){
    return GestureDetector(
      onTap: ()=> _cubit.saveWord(),
      child: AnimatedScale(
        scale: _cubit.state.loadstatus==LOADSTATUS.LOADING ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          height: 60,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: AppColors.greenGradient,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2A7A1C).withOpacity(0.7),
                blurRadius: 0,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: const Color(0xFF50C040).withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        child: Center(
            child: Text(" Lưu")),
        ),
      ),
    );
  }
}