'''
Created on Sep 16, 2010
kNN: k Nearest Neighbors

Input:      inX: vector to compare to existing dataset (1xN)
            dataSet: size m data set of known vectors (NxM)
            labels: data set labels (1xM vector)
            k: number of neighbors to use for comparison (should be an odd number)
            
Output:     the most popular class label

@author: pbharrin
'''

from __future__ import print_function
import numpy as np
import operator
from os import listdir


def createDataSet():
    group = np.array([[1.0,1.1],[1.0,1.0],[0,0],[0,0.1]])
    labels = ['A','A','B','B']
    return group, labels


def classify0(inX, dataSet, labels, k):
    diffMat = inX - dataSet
    sqDiffMat = diffMat**2
    sqDistances = sqDiffMat.sum(axis=1)
    distances = sqDistances**0.5
    sortedDistIndices = distances.argsort()
    classCount = {}
    for i in range(k):
        voteIlabel = labels[sortedDistIndices[i]]
        classCount[voteIlabel] = classCount.get(voteIlabel, 0) + 1
    sortedClassCount = sorted(classCount, key=classCount.get, reverse=True)
    return sortedClassCount[0]


# Python2
def classify0_2(inX, dataSet, labels, k):
    dataSetSize = dataSet.shape[0]
    diffMat = np.tile(inX, (dataSetSize,1)) - dataSet
    sqDiffMat = diffMat**2
    sqDistances = sqDiffMat.sum(axis=1)
    distances = sqDistances**0.5
    sortedDistIndicies = distances.argsort()     
    classCount={}          
    for i in range(k):
        voteIlabel = labels[sortedDistIndicies[i]]
        classCount[voteIlabel] = classCount.get(voteIlabel,0) + 1
    sortedClassCount = sorted(classCount.iteritems(), key=operator.itemgetter(1), reverse=True)
    return sortedClassCount[0][0]



def file2matrix(filename):
    fr = open(filename)
    numberOfLines = len(fr.readlines())         #get the number of lines in the file
    returnMat = np.zeros((numberOfLines,3))        #prepare matrix to return
    classLabelVector = []                       #prepare labels return   
    fr = open(filename)
    index = 0
    for line in fr.readlines():
        line = line.strip().split('\t')
        returnMat[index,:] = line[0:3]
        classLabelVector.append(int(line[-1]))
        index += 1
    return returnMat,classLabelVector
    
    
def autoNorm(dataSet):
    minVals = dataSet.min(0)
    maxVals = dataSet.max(0)
    ranges = maxVals - minVals
    
    normDataSet = (dataSet-minVals)/ranges
    return normDataSet, ranges, minVals


def datingClassTest(filename, k=3, hoRatio=0.10):
    datingDataMat, datingLabels = file2matrix(filename)
    normMat, ranges, minVals = autoNorm(datingDataMat)
    m = normMat.shape[0]              
    numTestVecs = int(m * hoRatio)    
    errorCount = 0.0
        
    for i in range(numTestVecs):
        classifierResult = classify0(normMat[i, :], normMat[numTestVecs:m, :], \
                                         datingLabels[numTestVecs:m], k)        
        if i%20 == 0 or (classifierResult != datingLabels[i]):
            print("the classifier came back with: %d, the real answer is: %d"\
                    % (classifierResult, datingLabels[i]))
            if (classifierResult != datingLabels[i]):
                errorCount += 1.0
                print("!!!NOT MATCHED!!!")
            
    print("the total correct rate is: %f" % (1-errorCount/float(numTestVecs)))

    
def classifyPerson(filename):
    resultList = ['not at all','in small doses', 'in large doses']
    percentTats = float(input(
                "percentage of time spent playing video games?"))
    ffMiles = float(input("frequent flier miles earned per year?"))
    iceCream = float(input("liters of ice cream consumed per year?"))
    datingDataMat,datingLabels = file2matrix(filename)
    normMat, ranges, minVals = autoNorm(datingDataMat)
    
    inArr = np.array([ffMiles, percentTats, iceCream])
    classifierResult = classify0((inArr-minVals)/ranges,normMat,datingLabels,3)
    print("You will probably like this person: ",\
        resultList[classifierResult - 1])
    
        
def img2vector(filename):
    returnVect = np.zeros((1,1024))
    fr = open(filename)
    for i in range(32):
        lineStr = fr.readline()
        for j in range(32):
            returnVect[0,32*i+j] = int(lineStr[j])
    return returnVect

def handwritingClassTest(foldername):
    hwLabels = []
    trainingFileList = listdir(foldername+'trainingDigits')           #load the training set
    m = len(trainingFileList)
    trainingMat = np.zeros((m,1024))
    for i in range(m):
        fileNameStr = trainingFileList[i]
        fileStr = fileNameStr.split('.')[0]     #take off .txt
        classNumStr = int(fileStr.split('_')[0])
        hwLabels.append(classNumStr)
        trainingMat[i,:] = img2vector(foldername+'trainingDigits/%s' % fileNameStr)
    testFileList = listdir(foldername+'testDigits')        #iterate through the test set
    errorCount = 0.0
    mTest = len(testFileList)
    for i in range(mTest):
        fileNameStr = testFileList[i]
        fileStr = fileNameStr.split('.')[0]     #take off .txt
        classNumStr = int(fileStr.split('_')[0])
        vectorUnderTest = img2vector(foldername+'testDigits/%s' % fileNameStr)
        classifierResult = classify0(vectorUnderTest, trainingMat, hwLabels, 3)
        if i%100 == 0 or classifierResult != classNumStr:
            print("the classifier came back with: %d, the real answer is: %d" % (classifierResult, classNumStr))
            if (classifierResult != classNumStr): 
                print("----- error!! %d --------------" %i); 
                errorCount += 1.0
    print("the total number of errors is: %d" % errorCount)
    print("the total correct rate is: %f" % (1-errorCount/float(mTest)))
