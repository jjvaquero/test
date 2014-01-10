
import ij.IJ;
import ij.gui.Roi;
//import ij.plugin.frame.RoiManager;
import ij.ImagePlus;
import ij.process.ImageProcessor;
//import ij.io.*;
//import ij.plugin.*;
import ij.process.ImageStatistics;
import ij.measure.Calibration;
import ij.measure.Measurements;
import ij.util.ArrayUtil;
//import ij.WindowManager;


public class miniMap_Detector  {
	//ImagePlus img;
	ImageProcessor myProc;
	Roi[] miniMapRois;
	//variables used in the classification
	int lysoMeanFactor;
	int lysoStdFactor;
	int gsoMeanFactor;
	int gsoStdFactor;
	public static int sizeX = 24; 
	public static int sizeY = 12;
	public static int miniMapWidth = 336;
	public static int miniMapHeight = 168;
	public static int detectorSize = 12;
	
	
	public miniMap_Detector(){
		//variables used in the classification
		lysoMeanFactor = 2;
		lysoStdFactor = 2;
		gsoMeanFactor = 2;
	    gsoStdFactor = 2;
		
		
		miniMapRois = new Roi[sizeX*sizeY];
		int index = 0;
		for (int y = 0; y <sizeY; y++){
			for ( int x = 0; x < sizeX; x++){
				// each ROI is a 12x12 square
				miniMapRois[index] = new Roi(x*(detectorSize+2),y*(detectorSize+2),detectorSize,detectorSize);
			}
			index++;
		}
	}

		
    public int[] Analyze(ImagePlus img) {
		//arg will contain the string with the image ID
    	

		//get the Image processor for the file that have been sent
		myProc = img.getProcessor();
		
		if (this.checkImageSize(myProc) > 0) return null;


		ImageProcessor tmpProc;  // extra image processor needed to work with the cropped versions
		ImageStatistics nStats = new ImageStatistics(); //
		Calibration nCal = img.getCalibration(); //calibration data needed by the getStatistics
		// I will need different arrays for the LYSO and the GSO 
		float[] LYSOmeans = new float[sizeX*sizeY/2];
		float[] LYSOstds = new float[sizeX*sizeY/2];
		float[] GSOmeans = new float[sizeX*sizeY/2];
		float[] GSOstds = new float[sizeX*sizeY/2];
		/*
		double[]  means = new double[sizeX*sizeY];
		double[] stdDevs = new double[sizeX*sizeY];
		*/
		
		//Roi [] rois = new Roi[sizeX*sizeY];
		int index = 0;
		
		img.updateAndDraw();
		
		
		//Divide the image in different ROIs and measure the mean and the std 
		//of the ROIs, ROIs will be stored in an array in case they are needed afterwards
		for (int y = 0; y <sizeY; y++){
			for ( int x = 0; x < sizeX; x++){
				// each ROI is a 12x12 square
				//rois[index] = new Roi(x*14,y*14,12,12);
				myProc.setRoi(miniMapRois[index]);
				// obtain a new image processor to get it's statistics
				tmpProc = myProc.crop();
				//get the data needed
				nStats = ImageStatistics.getStatistics(tmpProc, Measurements.MEAN+Measurements.STD_DEV,nCal); //6 = MEAN + STD_DEV
				if (y < sizeY/2){
					LYSOmeans[index] = (float) nStats.mean;
					LYSOstds[index] = (float) nStats.stdDev;
				}else{
					GSOmeans[index-(sizeX*sizeY/2)] = (float) nStats.mean;
					GSOstds[index-(sizeX*sizeY/2)] = (float) nStats.stdDev;
				}
				//means[index] = nStats.mean;
				//stdDevs[index] = nStats.stdDev;
				//myProc.draw(rois[index]);
				index++;	
				//used only to check that it works, can be commented later on
				//IJ.log("Cristal "+ String.valueOf(index-1)+ " media "+ String.valueOf(nStats.mean) + "desv "+String.valueOf(nStats.stdDev));
				//to make sure that ROIs are not added one to the other
				myProc.resetRoi();
				}			

		}
		
		//Now I try the same implementation as before...to see how it works...
		
		//to get the means from the 4 arrays, I will need an ArrayUtil object
		ArrayUtil aUtil = new ArrayUtil(LYSOmeans);
		float LYSOmeanVal = (float)aUtil.getMean();
		aUtil = new ArrayUtil(LYSOstds);
		float LYSOstdMean = (float) aUtil.getMean();
		aUtil = new ArrayUtil(GSOmeans);
		float GSOmeanVal = (float) aUtil.getMean();
		aUtil = new ArrayUtil(GSOstds);
		float GSOstdMean = (float) aUtil.getMean();

		//variables used in the classification
		int lysoMeanFactor = 2;
		int lysoStdFactor = 2;
		int gsoMeanFactor = 2;
		int gsoStdFactor = 2;
		
		int[] wrongCrystal = new int[sizeX*sizeY];
	    int nWrong = 0;
	    int n = sizeX*sizeY;

		for (int i = 0; i < n/2; i ++){
	    		wrongCrystal[i] = 0;
			    wrongCrystal[n/2+i] = 0;
			if (LYSOmeans[i] < (LYSOmeanVal-LYSOmeanVal/lysoMeanFactor)){
				wrongCrystal[i] = 1;
				nWrong++;
			}
			else if (LYSOstds[i] > (LYSOstdMean*lysoStdFactor)){
				wrongCrystal[i] = 1;
				nWrong++;
			}
		
			if (GSOmeans[i] < (GSOmeanVal-GSOmeanVal/gsoMeanFactor) || GSOmeans[i] > (GSOmeanVal+GSOmeanVal/gsoMeanFactor)){
				wrongCrystal[n/2+i] = 1;
				nWrong++;
			}
			else if (GSOstds[i] > (GSOstdMean*gsoStdFactor)){
				wrongCrystal[n/2+i] = 1;
				nWrong++;
			}
		}
		
		//Now I can plot the wrong crystals;
		//this.drawRois(myProc, wrongCrystal);
		
		IJ.log("Cristales mal "+String.valueOf(nWrong));
		
		//function needs to be called in order to see the modifications 
		// done to the original image
		img.updateAndDraw();
		
		//annado todas las roi a un roi manager
		//not needed can be taken out later
		/*RoiManager roiM = new RoiManager();
		for(int i = 0 ; i < sizeX*sizeY ; i++){
			roiM.addRoi(rois[i]);
		}*/
		return wrongCrystal;
	}
    
    public void drawRois(ImageProcessor imgProc, int[] wrongCrystals){
    	int n = sizeX*sizeY;
	    //check that the image has the correct size
		if (this.checkImageSize(imgProc) > 0) return;
		//Now I can plot the wrong crystals;
		imgProc.setColor(0xFFFFFF);
		for(int i = 0; i < n; i++){
			if(wrongCrystals[i]>0) imgProc.draw(miniMapRois[i]);
		}		

    }
    
    private int checkImageSize(ImageProcessor imgProc){
    	int height = imgProc.getHeight();
    	int width = imgProc.getWidth();
    	
    	if ( height != miniMapHeight || width != miniMapWidth) return 1;
    	return 0;
    }
    
    
}