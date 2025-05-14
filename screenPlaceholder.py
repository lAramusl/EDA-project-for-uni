import cv2
import numpy as np

if __name__ == "__main__":
    screen = np.zeros((480, 640, 3), dtype=np.uint8)
    notes = map()
    I, J, K = screen.shape

    staff_count = 9
    line_spacing = 7          # пикселей между линиями в одном стане
    staff_spacing = 53        # вертикальное расстояние между станами
    line_thickness = 1        # толщина линии
    top_offset = 15
    notes_spacing = 80
    notes_offset = 40

    for y in range(I):
        for x in range(J):
            # Проходим по всем 9 станам
            is_line = False
            for staff in range(staff_count):
                base_y = top_offset + staff * staff_spacing 
                for line_num in range(5):
                    line_y = base_y + line_num * line_spacing
                    if abs(y - line_y) < line_thickness:
                        is_line = True

            for color in range(K):
                if color == 0 or color == 1:  # red + green → жёлтый
                    screen[y][x][color] = 255 if is_line else 0
                else:
                    screen[y][x][color] = 0  # blue канал = 0

    cv2.imwrite("test.png", cv2.cvtColor(screen, cv2.COLOR_RGB2BGR))