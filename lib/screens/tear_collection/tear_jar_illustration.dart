import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'tear_mascot.dart';
import 'tear_painter.dart';

class TearJarIllustration extends StatelessWidget {
  const TearJarIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 230,
      child: Center(
        child: SizedBox(
          width: 280,
          height: 230,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Glass Jar & floating tears
              Positioned(
                left: 15,
                top: 10,
                child: SizedBox(
                  width: 175,
                  height: 210,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      // Cork lid
                      Positioned(
                        top: 0,
                        child: Container(
                          width: 112,
                          height: 22,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDEC3A0),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFC7A87F),
                              width: 1.2,
                            ),
                          ),
                        ),
                      ),

                      // Jar neck
                      Positioned(
                        top: 18,
                        child: Container(
                          width: 96,
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFE8F6F4,
                            ).withValues(alpha: 0.6),
                            border: Border.symmetric(
                              vertical: BorderSide(
                                color: const Color(0xFF71C3B6),
                                width: 2.5,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Jar body
                      Positioned(
                        top: 26,
                        child: Container(
                          width: 154,
                          height: 174,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFE8F7F4,
                            ).withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(38),
                            border: Border.all(
                              color: const Color(0xFF71C3B6),
                              width: 2.8,
                            ),
                          ),
                          child: Stack(
                            children: const [
                              Positioned(
                                left: 52,
                                top: 32,
                                child: Teardrop(
                                  width: 15,
                                  height: 20,
                                  color: AppColors.secondary,
                                ),
                              ),

                              // 2. Orange tear (upper-right)
                              Positioned(
                                left: 78,
                                top: 52,
                                child: Teardrop(
                                  width: 16,
                                  height: 22,
                                  color: AppColors.primary,
                                ),
                              ),

                              // 3. Teal tear (lower-left)
                              Positioned(
                                left: 24,
                                top: 96,
                                child: Teardrop(
                                  width: 22,
                                  height: 29,
                                  color: AppColors.secondary,
                                ),
                              ),

                              // 4. Pink/coral tear (middle-right)
                              Positioned(
                                right: 28,
                                top: 104,
                                child: Teardrop(
                                  width: 20,
                                  height: 26,
                                  color: Color(0xFFEB8481),
                                ),
                              ),

                              // 5. Orange tear (bottom-center)
                              Positioned(
                                left: 66,
                                bottom: 22,
                                child: Teardrop(
                                  width: 20,
                                  height: 26,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Positioned(
                right: 24,
                bottom: 12,
                child: SproutMascot(
                  width: 72,
                  height: 94,
                  showGroundRipples: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
