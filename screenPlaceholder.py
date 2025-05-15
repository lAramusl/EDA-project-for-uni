import cv2
import numpy as np

staff_count = 9
line_spacing = 7          # пикселей между линиями в одном стане
staff_spacing = 53        # вертикальное расстояние между станами
line_thickness = 1        # толщина линии
top_offset = 15
notes_spacing = 80
notes_offset = 40
octava = 4

notesPixelOffsets = {
            "A1" : -2,
            "C" : -1,
            "D" : 0,
            "E" : 1,
            "F" : 2,
            "G" : 3,
            "A" : 4,
            "B" : 5,
            "C1": 6,
            "D1": 7
            }

note_semitone_offsets = {
    "A1": 0,
    "B": 2,
    "C1": 3,
    "C": -9,
    "D1": 5,
    "D": -7,
    "E": -5,
    "F": -4,
    "G": -2,
    "A": 0,
}

note_line_offsets = {
    "A1": -6,   # базовая — 2-я линейка
    "B": 1,
    "C1": 2,
    "D1": 3,
    "C": -5,
    "D": -4,
    "E": -3,
    "F": -2,
    "G": -1,
    "A": 0,    # A5 — совпадает с A4 по линейке
}


def draw_stawes (screen):
    I, J, K = screen.shape

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
    
    return screen

def draw_notes(screen, notes_y):
    radius = 4  # радиус окружности (можно подстроить под размер ноты)
    
    for staff_index, staff_notes in enumerate(notes_y):
        for note_index, note_y in enumerate(staff_notes):
            note_x = notes_offset + note_index * notes_spacing
            center = (note_x, note_y)
            cv2.circle(screen, center, radius, (0, 255, 0), thickness=-1)

def getYs(notes):
    ans = []
    for staff_index in range(len(notes)):
        staff_y = top_offset + staff_index * staff_spacing
        base_y = staff_y + 2 * line_spacing  # A1 на второй линейке (снизу вверх: 0,1,**2**,3,4)
        row = []
        for note in notes[staff_index]:
            offset = note_line_offsets[note]
            y = base_y - offset * (line_spacing / 2)
            row.append(int(y))
        ans.append(row)
    return ans



if __name__ == "__main__":
    screen = np.zeros((480, 640, 3), dtype=np.uint8)
    
    
    notes = ("E G D C D E G D".split(),
             "E G D1 C1 G F E D".split(),
             "E G D C D E G D".split(),
             "E G D1 C1 G".split(),
             "G F E F E C".split(),
             "F E D E D A1".split(),
             "G F E F E C F C1".split(),
             "E G D C D E G D".split(),
             "E G D1 C1 G".split())
    
    

    screen = draw_stawes(screen)
    noteYs = getYs(notes)
    draw_notes(screen, noteYs)
    for i in noteYs:
        print(i)
    #cv2.imwrite("test.png", cv2.cvtColor(screen, cv2.COLOR_RGB2BGR))