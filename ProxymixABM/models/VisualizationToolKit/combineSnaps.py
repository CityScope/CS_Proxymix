import os
import argparse

def combine(outFname = 'test.mp4',quality=20,frameRate = '24',aspectRatio='2560x1049'):
	'''
	Combine set of png files into a mp4 video.
	Images need to be in the same directory as the script.

	Parameters
	----------
	outFname : str ('test.mp4')
		Filename for outfile
	quality : int (20)
		Quality (lower is higher)
	frameRate : int (60)
		Frame rate of video.
	aspectRatio : str ('2560x1049')
		Aspect ratio of images.
	'''
	fnames = [f for f in os.listdir('.') if 'png'==f.split('.')[-1]]
	cycles = [int(f.split('cycle_')[-1].split('_')[0].replace('.png','')) for f in fnames]
	order = sorted(range(len(cycles)), key=lambda k: cycles[k])

	digits = 5
	j = 0
	for i in order:
		src = fnames[i]
		dst = 'cycle_'+('0'*digits+str(j))[-digits:]+'.png'
		print(src,dst)
		os.rename(src, dst)
		j+=1

	# cmd = f'ffmpeg -r {frameRate} -f image2 -s {aspectRatio} -i cycle_%0{digits}d.png -vf scale=1280:-2 -vcodec libx264 -crf {quality}  -pix_fmt yuv420p {outFname}'
	cmd = f'ffmpeg -r {frameRate} -f image2 -pattern_type glob -i cycle_%0{digits}d.png -vcodec libx264 -crf {quality} -pix_fmt yuv420p {outFname}'
	print(cmd)
	os.system(cmd)
	

if __name__ == "__main__":
	parser = argparse.ArgumentParser()
	parser.add_argument('-outfname', type=str, help='Filname for outfile')
	parser.add_argument('-framerate', type=int, help='Video frame rate')
	args = parser.parse_args()
	
	combine(
		outFname = 'test.mp4' if args.outfname is None else args.outfname,
		quality = 20,
		frameRate = '24' if args.framerate is None else args.framerate,
		aspectRatio='2560x1049'
	)
