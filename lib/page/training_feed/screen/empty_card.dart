import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:test_abc/commons/app_images.dart';
import 'package:test_abc/generated/l10n.dart';
import 'package:test_abc/commons/app_colors.dart';
import 'package:test_abc/page/training_feed/training_feed_cubit.dart';
import 'package:test_abc/page/training_feed/widgets/shared_widgets.dart';
import 'package:test_abc/page/training_feed/widgets/training_feed_card.dart';
import 'package:test_abc/page/training_feed/widgets/widget_card_common.dart';
import 'package:test_abc/router/router.dart';

class EmptyCard extends StatelessWidget {
  final bool isEmbedInHome;
  const EmptyCard({required this.isEmbedInHome});


  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return InkWell(
      onTap: () =>context.push(Routes.addWord),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          isEmbedInHome ? (topPadding + 68) : (topPadding + 80),
          16,
          105,
        ),
        child: CardShell(
          shimmer: true,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(S.of(context).no_words_yet,
                    style: const TextStyle(
                      color: AppColors.xoayPaper,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    )
                ),
                Text(S.of(context).add_words_first,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.xoayPaper.withOpacity(0.7),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                InkWell(onTap: () =>context.push(Routes.addWord),
                    child: SvgPicture.asset(AppImages.icAddSquare,
                    width: 68, height: 68,)
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}