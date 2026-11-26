# Companion animation source notes

The built-in ImageGen tool used the original runtime sprites as references.
The generated art was aligned to the original atlas pivots for packing.

## Capybara

The [four aligned pose cells](../sources/customer-capybara-poses.png) follow the
existing standing frame. The generated crouch and sit supply the hindquarters,
with the original head, front paws, customer, and leash kept in place. Closed
eyelids were finished at the runtime pixel size.

> Use case: precise-object-edit. Produce a transparent sprite pose reference sheet for the capybara in the input. Output three isolated full-body versions of ONLY the capybara in well-separated horizontal columns of equal size, with identical head proportions and exact palette and pixel-art rendering as input. Left: same standing pose but visibly closed dark eyelid. Middle: halfway lowering hindquarters, front paws planted. Right: fully seated on its haunches with hind paws tucked, front legs still straight/on the ground, head held up like the original. All three face right with the exact same three-quarter angle as the original. Match the short rounded ears, squared muzzle, amber fur and dark teal chest/body harness. Fur shading should match clusters of the pixel art input. No man or leash, no labels, no additional entities, no frames or grid lines, no shadow. True transparent background.

## Rainbow duo

The [aligned kiss frame](../sources/customer-rainbow-duo-kiss.png) follows the
existing idle frame. The heart is drawn by Godot.

> Use case: identity-preserve. Create one transparent full-body 2D pixel-art game sprite frame, a short affectionate closed-mouth kiss between these two adult male partners. Exact same two men, short man with dark hair/beard/glasses and colorful shirt still holding their little orange dog at his chest, tall red-haired bearded man in open plaid shirt over gray rainbow T-shirt bends left at his torso and slightly at his knees in profile so their lips actually meet. The shorter man tips his face up and right. Their eyes close softly. Keep the four sandals as close as possible to their exact original screen positions and same shared floor baseline. Preserve the exact outfits, body types, dog, relative sizes, plum outlines, warm highlights, and crisp authentic pixel-art clustered color/shadows of the reference. Match reference silhouettes from waist down and retain the frame's original margins and framing. All figures and shoes completely visible, true transparent pixels around and between figures. No floor or backdrop, no letters or hearts.
